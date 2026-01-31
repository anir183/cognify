package blockchain

import (
	"errors"
	"fmt"
	"log"
	"sync"
	"time"
)

// MockBlockchainClient simulates blockchain interactions for development
type MockBlockchainClient struct {
	certificates map[string]bool // Hash -> exists on chain
	mu           sync.RWMutex
}

var (
	mockClient *MockBlockchainClient
	once       sync.Once
)

// InitMockBlockchain initializes the mock blockchain client
func InitMockBlockchain() {
	once.Do(func() {
		mockClient = &MockBlockchainClient{
			certificates: make(map[string]bool),
		}
		log.Println("✅ Mock Blockchain client initialized")
	})
}

// GetMockClient returns the singleton mock blockchain client
func GetMockClient() *MockBlockchainClient {
	if mockClient == nil {
		InitMockBlockchain()
	}
	return mockClient
}

// VerifyCertificateHash checks if a certificate hash exists on the blockchain
func (c *MockBlockchainClient) VerifyCertificateHash(hash string) (bool, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	
	// Simulate network delay
	time.Sleep(100 * time.Millisecond)
	
	exists := c.certificates[hash]
	return exists, nil
}

// MintCertificate adds a certificate hash to the blockchain
func (c *MockBlockchainClient) MintCertificate(hash string) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	
	// Check if already minted
	if c.certificates[hash] {
		return "", errors.New("certificate already minted on blockchain")
	}
	
	// Simulate blockchain transaction
	time.Sleep(200 * time.Millisecond)
	
	// Mark as minted
	c.certificates[hash] = true
	
	// Generate mock transaction hash
	txHash := fmt.Sprintf("0x%s", hash[:40])
	
	log.Printf("🔗 Certificate minted on blockchain: %s (tx: %s)", hash[:16]+"...", txHash[:16]+"...")
	
	return txHash, nil
}

// GetCertificateCount returns the total number of certificates on chain
func (c *MockBlockchainClient) GetCertificateCount() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.certificates)
}

// TODO: Real blockchain implementation
// Uncomment when ready to integrate with Ethereum/Polygon
/*
import (
	"context"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/common"
)

type BlockchainClient struct {
	client   *ethclient.Client
	contract common.Address
}

func InitBlockchain(rpcURL, contractAddr string) (*BlockchainClient, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, err
	}
	
	return &BlockchainClient{
		client:   client,
		contract: common.HexToAddress(contractAddr),
	}, nil
}
*/
