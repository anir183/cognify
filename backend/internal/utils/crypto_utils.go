package utils

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"

	"golang.org/x/crypto/pbkdf2"
)

// EncryptPrivateKey encrypts a private key using AES-256-GCM
func EncryptPrivateKey(privateKey, passphrase string) (string, error) {
	if privateKey == "" || passphrase == "" {
		return "", errors.New("private key and passphrase cannot be empty")
	}

	// Derive a 32-byte key from passphrase using PBKDF2
	salt := make([]byte, 32)
	if _, err := io.ReadFull(rand.Reader, salt); err != nil {
		return "", err
	}

	key := pbkdf2.Key([]byte(passphrase), salt, 100000, 32, sha256.New)

	// Create AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	// Use GCM mode
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// Create nonce
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	// Encrypt
	ciphertext := gcm.Seal(nonce, nonce, []byte(privateKey), nil)

	// Combine salt + ciphertext and encode to base64
	result := append(salt, ciphertext...)
	return base64.StdEncoding.EncodeToString(result), nil
}

// DecryptPrivateKey decrypts an encrypted private key
func DecryptPrivateKey(encrypted, passphrase string) (string, error) {
	if encrypted == "" || passphrase == "" {
		return "", errors.New("encrypted key and passphrase cannot be empty")
	}

	// Decode from base64
	data, err := base64.StdEncoding.DecodeString(encrypted)
	if err != nil {
		return "", err
	}

	// Extract salt (first 32 bytes)
	if len(data) < 32 {
		return "", errors.New("invalid encrypted data")
	}
	salt := data[:32]
	ciphertext := data[32:]

	// Derive key from passphrase
	key := pbkdf2.Key([]byte(passphrase), salt, 100000, 32, sha256.New)

	// Create AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	// Use GCM mode
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// Extract nonce
	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		return "", errors.New("invalid ciphertext")
	}
	nonce, ciphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]

	// Decrypt
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}

// HashToBytes32 converts a hex string hash to bytes32 format for smart contract
func HashToBytes32(hash string) ([32]byte, error) {
	var result [32]byte
	
	// Remove 0x prefix if present
	if len(hash) >= 2 && hash[:2] == "0x" {
		hash = hash[2:]
	}
	
	if len(hash) != 64 {
		return result, errors.New("hash must be 64 characters (32 bytes)")
	}
	
	// Convert hex string to bytes
	bytes := []byte(hash)
	for i := 0; i < 32; i++ {
		result[i] = bytes[i*2]<<4 | bytes[i*2+1]
	}
	
	return result, nil
}
