package blockchain

import (
	"context"
	"fmt"
	"log"
	"time"

	"cache-crew/cognify/internal/db"

	"cloud.google.com/go/firestore"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Event Signatures
var (
	EventCertificateMinted  = crypto.Keccak256Hash([]byte("CertificateMinted(bytes32,address,address)"))
	EventCertificateRevoked = crypto.Keccak256Hash([]byte("CertificateRevoked(bytes32,address,string)"))
	EventIssuerAuthorized   = crypto.Keccak256Hash([]byte("IssuerAuthorized(address)"))
	EventIssuerRevoked      = crypto.Keccak256Hash([]byte("IssuerRevoked(address)"))
)

// EventListener handles blockchain subscriptions
type EventListener struct {
	client          *ethclient.Client
	contractAddress common.Address
	rpcURL          string
}

// NewEventListener creates a new listener
func NewEventListener(rpcURL, contractAddr string) (*EventListener, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Ethereum RPC: %v", err)
	}

	return &EventListener{
		client:          client,
		contractAddress: common.HexToAddress(contractAddr),
		rpcURL:          rpcURL,
	}, nil
}

// Start begins listening to events
func (l *EventListener) Start(ctx context.Context) {
	query := ethereum.FilterQuery{
		Addresses: []common.Address{l.contractAddress},
	}

	logs := make(chan types.Log)
	sub, err := l.client.SubscribeFilterLogs(ctx, query, logs)
	if err != nil {
		log.Printf("[Blockchain] ⚠️ Failed to subscribe to logs (WebSocket might be missing). Polling fallback not implemented yet. Error: %v", err)
		return // In production, implement polling fallback or ensure WS RPC
	}

	log.Printf("[Blockchain] 🎧 Listening for events on %s", l.contractAddress.Hex())

	go func() {
		for {
			select {
			case err := <-sub.Err():
				log.Printf("[Blockchain] Subscription error: %v. Reconnecting...", err)
				l.reconnect(ctx)
				return
			case vLog := <-logs:
				l.handleLog(vLog)
			case <-ctx.Done():
				return
			}
		}
	}()
}

func (l *EventListener) reconnect(ctx context.Context) {
	time.Sleep(5 * time.Second) // Backoff
	client, err := ethclient.Dial(l.rpcURL)
	if err == nil {
		l.client = client
		l.Start(ctx)
	} else {
		log.Printf("[Blockchain] Reconnect failed: %v", err)
		l.reconnect(ctx) // Infinite retry
	}
}

func (l *EventListener) handleLog(vLog types.Log) {
	switch vLog.Topics[0] {
	case EventCertificateMinted:
		l.handleCertificateMinted(vLog)
	case EventCertificateRevoked:
		l.handleCertificateRevoked(vLog)
	case EventIssuerAuthorized:
		l.handleIssuerAuthorized(vLog)
	case EventIssuerRevoked:
		l.handleIssuerRevoked(vLog)
	}
}

func (l *EventListener) handleCertificateMinted(vLog types.Log) {
	// Topics: [Signature, CertHash, Owner, Issuer]
	if len(vLog.Topics) < 4 {
		return
	}
	certHash := vLog.Topics[1]
	owner := common.HexToAddress(vLog.Topics[2].Hex())
	// issuer := common.HexToAddress(vLog.Topics[3].Hex())
	// log.Printf("[Blockchain] 🟢 Certificate Minted: %s (Owner: %s)", certHash.Hex(), owner.Hex())
	log.Printf("[Blockchain] 🟢 Certificate Minted: %s (Owner: %s) by %s", certHash.Hex(), owner.Hex(), vLog.Topics[3].Hex())

	// Sync to Firebase
	if db.FirestoreClient != nil {
		updates := map[string]interface{}{
			"isMinted": true,
			"txHash":   vLog.TxHash.Hex(),
			"block":    vLog.BlockNumber,
			"mintedAt": time.Now(),
			"revoked":  false,
		}

		_, err := db.FirestoreClient.Collection("certificates").Doc(certHash.Hex()).Set(context.Background(), updates, firestore.MergeAll)
		if err != nil {
			log.Printf("[Blockchain] Failed to sync mint event: %v", err)
		}
	}
}

func (l *EventListener) handleCertificateRevoked(vLog types.Log) {
	// Topics: [Signature, CertHash, Issuer]
	// Data: [Reason string] - Handling omitted for simplicity
	if len(vLog.Topics) < 3 {
		return
	}
	certHash := vLog.Topics[1]

	log.Printf("[Blockchain] 🔴 Certificate Revoked: %s", certHash.Hex())

	if db.FirestoreClient != nil {
		_, err := db.FirestoreClient.Collection("certificates").Doc(certHash.Hex()).Set(context.Background(), map[string]interface{}{
			"revoked":   true,
			"revokedAt": time.Now(),
		}, firestore.MergeAll)
		if err != nil {
			log.Printf("[Blockchain] Failed to sync revoke event: %v", err)
		}
	}
}

func (l *EventListener) handleIssuerAuthorized(vLog types.Log) {
	// Topics: [Signature, IssuerAddress]
	if len(vLog.Topics) < 2 {
		return
	}
	issuer := common.HexToAddress(vLog.Topics[1].Hex())
	log.Printf("[Blockchain] 🛡️ Issuer Authorized: %s", issuer.Hex())

	if db.FirestoreClient != nil {
		// Find user by wallet address and update
		// Assuming wallet_address is indexed or we use query
		// Ideally, we might store users by ID, but searching by wallet is needed.
		// Or we can maintain a separate 'authorized_issuers' collection for quick lookup

		// 1. Update User Record (if exists)
		iter := db.FirestoreClient.Collection("users").Where("wallet_address", "==", issuer.Hex()).Documents(context.Background())
		for {
			doc, err := iter.Next()
			if err != nil {
				break
			}
			doc.Ref.Set(context.Background(), map[string]interface{}{
				"isAuthorized": true,
				"role":         "instructor", // Force role update
			}, firestore.MergeAll)
		}
	}
}

func (l *EventListener) handleIssuerRevoked(vLog types.Log) {
	// Topics: [Signature, IssuerAddress]
	if len(vLog.Topics) < 2 {
		return
	}
	issuer := common.HexToAddress(vLog.Topics[1].Hex())
	log.Printf("[Blockchain] 🚫 Issuer Revoked: %s", issuer.Hex())

	if db.FirestoreClient != nil {
		iter := db.FirestoreClient.Collection("users").Where("wallet_address", "==", issuer.Hex()).Documents(context.Background())
		for {
			doc, err := iter.Next()
			if err != nil {
				break
			}
			doc.Ref.Set(context.Background(), map[string]interface{}{
				"isAuthorized": false,
			}, firestore.MergeAll)
		}
	}
}
