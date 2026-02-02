package blockchain

import (
	"context"
	"log"
	"math/big"
	"time"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"

	"cloud.google.com/go/firestore"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// SyncWorker handles periodic blockchain synchronization
type SyncWorker struct {
	client          *ethclient.Client
	contractAddress common.Address
	rpcURL          string
	interval        time.Duration
}

// NewSyncWorker creates a new sync worker
func NewSyncWorker(rpcURL, contractAddr string, interval time.Duration) (*SyncWorker, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, err
	}

	return &SyncWorker{
		client:          client,
		contractAddress: common.HexToAddress(contractAddr),
		rpcURL:          rpcURL,
		interval:        interval,
	}, nil
}

// Start begins the periodic sync
func (w *SyncWorker) Start(ctx context.Context) {
	log.Printf("[SyncWorker] 🕒 Starting background sync (Interval: %s)", w.interval)
	ticker := time.NewTicker(w.interval)

	go func() {
		for {
			select {
			case <-ticker.C:
				w.sync(ctx)
			case <-ctx.Done():
				ticker.Stop()
				return
			}
		}
	}()
}

func (w *SyncWorker) sync(ctx context.Context) {
	if db.FirestoreClient == nil {
		return // Skip in mock mode (no DB)
	}

	// 1. Get last synced block
	lastBlock := w.getLastSyncedBlock(ctx)

	// 2. Get current block
	currentBlock, err := w.client.BlockNumber(ctx)
	if err != nil {
		log.Printf("[SyncWorker] ⚠️ Failed to get current block: %v", err)
		return
	}

	if lastBlock >= currentBlock {
		return // Already up to date
	}

	// 3. Query logs from lastBlock+1 to currentBlock
	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(int64(lastBlock + 1)),
		ToBlock:   big.NewInt(int64(currentBlock)),
		Addresses: []common.Address{w.contractAddress},
	}

	logs, err := w.client.FilterLogs(ctx, query)
	if err != nil {
		log.Printf("[SyncWorker] ⚠️ Failed to filter logs: %v", err)
		return
	}

	if len(logs) > 0 {
		log.Printf("[SyncWorker] 📥 Processing %d missed events (Blocks %d-%d)", len(logs), lastBlock+1, currentBlock)
		for _, vLog := range logs {
			w.processLog(ctx, vLog)
		}
	}

	// 4. Update last synced block
	w.updateLastSyncedBlock(ctx, currentBlock)
}

func (w *SyncWorker) processLog(ctx context.Context, vLog types.Log) {
	// Re-use logic from listener (or duplicate for robustness/independence)
	// Ideally refactor shared logic, but for now duplicating simple logic is safer than complex refactor
	switch vLog.Topics[0] {
	case EventCertificateMinted:
		if len(vLog.Topics) >= 4 {
			certHash := vLog.Topics[1]
			// Ensure it exists in DB
			_, err := db.FirestoreClient.Collection("certificates").Doc(certHash.Hex()).Set(ctx, map[string]interface{}{
				"isMinted": true,
				"txHash":   vLog.TxHash.Hex(),
				"block":    vLog.BlockNumber,
				"revoked":  false, // Reset if re-minted? Unlikely.
			}, firestore.MergeAll)
			if err != nil {
				log.Printf("[SyncWorker] DB Error: %v", err)
			}
		}
	case EventCertificateRevoked:
		if len(vLog.Topics) >= 2 {
			certHash := vLog.Topics[1]
			_, err := db.FirestoreClient.Collection("certificates").Doc(certHash.Hex()).Set(ctx, map[string]interface{}{
				"revoked":   true,
				"revokedAt": time.Now(),
			}, firestore.MergeAll)
			if err != nil {
				log.Printf("[SyncWorker] DB Error: %v", err)
			}
		}
	}
}

func (w *SyncWorker) getLastSyncedBlock(ctx context.Context) uint64 {
	doc, err := db.FirestoreClient.Collection("system_state").Doc("sync_state").Get(ctx)
	if err != nil {
		// If missing, start from 0 (or a recent safe block if configured)
		return 0
	}
	var state models.SystemState
	doc.DataTo(&state)
	return state.LastSyncedBlock
}

func (w *SyncWorker) updateLastSyncedBlock(ctx context.Context, block uint64) {
	_, err := db.FirestoreClient.Collection("system_state").Doc("sync_state").Set(ctx, map[string]interface{}{
		"lastSyncedBlock": block,
		"updatedAt":       time.Now(),
	}, firestore.MergeAll)
	if err != nil {
		log.Printf("[SyncWorker] Failed to update sync state: %v", err)
	}
}
