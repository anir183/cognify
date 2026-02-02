package utils

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"
)

// GenerateCertificateHash creates a unique SHA256 hash for a certificate
// Hash is based on student ID, course ID, and timestamp
func GenerateCertificateHash(studentID, courseID string, timestamp time.Time) string {
	// Create a unique string combining all identifiers
	data := fmt.Sprintf("%s:%s:%d", studentID, courseID, timestamp.Unix())

	// Generate SHA256 hash
	hash := sha256.Sum256([]byte(data))

	// Convert to hex string
	return hex.EncodeToString(hash[:])
}

// GenerateBlockchainTxHash creates a mock blockchain transaction hash
func GenerateBlockchainTxHash(certHash string) string {
	// In production, this would be the actual blockchain transaction hash
	// For now, we generate a mock hash
	data := fmt.Sprintf("tx:%s:%d", certHash, time.Now().UnixNano())
	hash := sha256.Sum256([]byte(data))
	return "0x" + hex.EncodeToString(hash[:])[:40] // Ethereum-style tx hash
}

// ValidateHash checks if a hash is valid (64 character hex string)
func ValidateHash(hash string) bool {
	if len(hash) != 64 {
		return false
	}

	// Check if all characters are valid hex
	_, err := hex.DecodeString(hash)
	return err == nil
}

// GenerateHash creates a simple SHA256 hash of a string
func GenerateHash(data string) string {
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}
