package utils

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
)

// GenerateAcademicDNA creates a unique Academic DNA hash for a Cognify user
// Formula: SHA256(wallet_address + student_id + enrollment_timestamp + platform_secret)
func GenerateAcademicDNA(walletAddress, studentID string, enrollmentTime time.Time, platformSecret string) string {
	// Normalize wallet address to lowercase
	normalizedWallet := strings.ToLower(walletAddress)

	// Create unique data string
	data := fmt.Sprintf("%s:%s:%d:%s",
		normalizedWallet,
		studentID,
		enrollmentTime.Unix(),
		platformSecret,
	)

	// Generate SHA256 hash
	hash := sha256.Sum256([]byte(data))

	// Return hex-encoded hash
	return hex.EncodeToString(hash[:])
}

// FormatAcademicDNA formats the DNA hash for display (first 8 + last 8 chars)
func FormatAcademicDNA(dna string) string {
	if len(dna) < 16 {
		return dna
	}
	return fmt.Sprintf("%s...%s", dna[:8], dna[len(dna)-8:])
}

// ValidateAcademicDNA checks if a DNA hash is valid (64 hex characters)
func ValidateAcademicDNA(dna string) bool {
	if len(dna) != 64 {
		return false
	}

	// Check if all characters are valid hex
	_, err := hex.DecodeString(dna)
	return err == nil
}
