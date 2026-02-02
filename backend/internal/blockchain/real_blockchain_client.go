package blockchain

import (
	"context"
	"crypto/ecdsa"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"math/big"
	"strings"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// RealBlockchainClient handles real blockchain interactions
type RealBlockchainClient struct {
	client       *ethclient.Client
	contractAddr common.Address
	privateKey   *ecdsa.PrivateKey
	publicKey    *ecdsa.PublicKey
	address      common.Address
	chainID      *big.Int
	mu           sync.RWMutex
}

var (
	realClient     *RealBlockchainClient
	realClientOnce sync.Once
)

// InitRealBlockchain initializes the real blockchain client
func InitRealBlockchain(rpcURL, contractAddr, privateKeyHex string) error {
	var initErr error

	realClientOnce.Do(func() {
		// Connect to Ethereum/Polygon node
		client, err := ethclient.Dial(rpcURL)
		if err != nil {
			initErr = fmt.Errorf("failed to connect to blockchain: %w", err)
			return
		}

		// Parse private key
		privateKeyHex = strings.TrimPrefix(privateKeyHex, "0x")
		privateKey, err := crypto.HexToECDSA(privateKeyHex)
		if err != nil {
			initErr = fmt.Errorf("invalid private key: %w", err)
			return
		}

		// Derive public key and address
		publicKey := privateKey.Public()
		publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
		if !ok {
			initErr = errors.New("failed to cast public key to ECDSA")
			return
		}

		address := crypto.PubkeyToAddress(*publicKeyECDSA)

		// Get chain ID
		chainID, err := client.ChainID(context.Background())
		if err != nil {
			initErr = fmt.Errorf("failed to get chain ID: %w", err)
			return
		}

		realClient = &RealBlockchainClient{
			client:       client,
			contractAddr: common.HexToAddress(contractAddr),
			privateKey:   privateKey,
			publicKey:    publicKeyECDSA,
			address:      address,
			chainID:      chainID,
		}

		log.Printf("✅ Real Blockchain client initialized")
		log.Printf("   RPC: %s", rpcURL)
		log.Printf("   Contract: %s", contractAddr)
		log.Printf("   Wallet: %s", address.Hex())
		log.Printf("   Chain ID: %s", chainID.String())
	})

	return initErr
}

// GetRealClient returns the singleton real blockchain client
func GetRealClient() *RealBlockchainClient {
	return realClient
}

// VerifyCertificateHash checks if a certificate exists on the blockchain
func (bc *RealBlockchainClient) VerifyCertificateHash(certHash string) (bool, error) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	if bc.client == nil {
		return false, errors.New("blockchain client not initialized")
	}

	// Convert hash to bytes32
	hashBytes, err := hexToBytes32(certHash)
	if err != nil {
		return false, err
	}

	// Call contract's verifyCertificate function
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Create contract instance
	contract, err := bc.getContractInstance()
	if err != nil {
		return false, err
	}

	// Call verifyCertificate
	exists, issuer, timestamp, err := contract.VerifyCertificate(&bind.CallOpts{Context: ctx}, hashBytes)
	if err != nil {
		return false, fmt.Errorf("contract call failed: %w", err)
	}

	log.Printf("🔍 Certificate verification: exists=%v, issuer=%s, timestamp=%d", exists, issuer.Hex(), timestamp)

	return exists, nil
}

// MintCertificate mints a new certificate on the blockchain
func (bc *RealBlockchainClient) MintCertificate(certHash string) (string, error) {
	bc.mu.Lock()
	defer bc.mu.Unlock()

	if bc.client == nil {
		return "", errors.New("blockchain client not initialized")
	}

	// Convert hash to bytes32
	hashBytes, err := hexToBytes32(certHash)
	if err != nil {
		return "", err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// Get nonce
	nonce, err := bc.client.PendingNonceAt(ctx, bc.address)
	if err != nil {
		return "", fmt.Errorf("failed to get nonce: %w", err)
	}

	// Get gas price
	gasPrice, err := bc.client.SuggestGasPrice(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get gas price: %w", err)
	}

	// Create auth
	auth, err := bind.NewKeyedTransactorWithChainID(bc.privateKey, bc.chainID)
	if err != nil {
		return "", fmt.Errorf("failed to create transactor: %w", err)
	}

	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(300000)
	auth.GasPrice = gasPrice
	auth.Context = ctx

	// Get contract instance
	contract, err := bc.getContractInstance()
	if err != nil {
		return "", err
	}

	// Send transaction
	tx, err := contract.MintCertificate(auth, hashBytes)
	if err != nil {
		return "", fmt.Errorf("failed to mint certificate: %w", err)
	}

	log.Printf("🔗 Certificate minting transaction sent: %s", tx.Hash().Hex())
	log.Printf("   Gas Price: %s wei", gasPrice.String())
	log.Printf("   Nonce: %d", nonce)

	// Wait for transaction to be mined
	receipt, err := bind.WaitMined(ctx, bc.client, tx)
	if err != nil {
		return "", fmt.Errorf("transaction mining failed: %w", err)
	}

	if receipt.Status == 0 {
		return "", errors.New("transaction failed")
	}

	log.Printf("✅ Certificate minted successfully!")
	log.Printf("   Block: %d", receipt.BlockNumber.Uint64())
	log.Printf("   Gas Used: %d", receipt.GasUsed)

	return tx.Hash().Hex(), nil
}

// GetCertificateCount returns total certificates on chain
func (bc *RealBlockchainClient) GetCertificateCount() (int, error) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	if bc.client == nil {
		return 0, errors.New("blockchain client not initialized")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	contract, err := bc.getContractInstance()
	if err != nil {
		return 0, err
	}

	count, err := contract.GetTotalCertificates(&bind.CallOpts{Context: ctx})
	if err != nil {
		return 0, fmt.Errorf("failed to get certificate count: %w", err)
	}

	return int(count.Int64()), nil
}

// GetBalance returns the wallet balance in wei
func (bc *RealBlockchainClient) GetBalance() (*big.Int, error) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	if bc.client == nil {
		return nil, errors.New("blockchain client not initialized")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	balance, err := bc.client.BalanceAt(ctx, bc.address, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get balance: %w", err)
	}

	return balance, nil
}

// getContractInstance returns a contract instance
func (bc *RealBlockchainClient) getContractInstance() (*CertificateRegistryContract, error) {
	// This will use the generated contract bindings
	// For now, return a placeholder
	return NewCertificateRegistryContract(bc.contractAddr, bc.client)
}

// hexToBytes32 converts hex string to [32]byte
func hexToBytes32(hexStr string) ([32]byte, error) {
	var result [32]byte

	hexStr = strings.TrimPrefix(hexStr, "0x")
	if len(hexStr) != 64 {
		return result, fmt.Errorf("invalid hash length: expected 64, got %d", len(hexStr))
	}

	bytes, err := hex.DecodeString(hexStr)
	if err != nil {
		return result, err
	}

	copy(result[:], bytes)
	return result, nil
}
