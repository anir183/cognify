package services

import (
	"crypto/rand"
	"fmt"
	"log"
	"sync"
	"time"
)

const (
	OTPLength   = 6
	OTPValidity = 180 * time.Second // 180 seconds = 3 minutes
)

type OTPEntry struct {
	Code      string
	Email     string
	ExpiresAt time.Time
}

type OTPStore struct {
	mu    sync.RWMutex
	store map[string]OTPEntry // email -> OTPEntry
}

var otpStore = &OTPStore{
	store: make(map[string]OTPEntry),
}

// GenerateOTP creates a new 6-digit OTP for the given email
func GenerateOTP(email string) (string, error) {
	code, err := generateRandomCode(OTPLength)
	if err != nil {
		return "", err
	}

	otpStore.mu.Lock()
	defer otpStore.mu.Unlock()

	otpStore.store[email] = OTPEntry{
		Code:      code,
		Email:     email,
		ExpiresAt: time.Now().Add(OTPValidity),
	}

	log.Printf("OTP generated for %s: %s (expires in 180s)", email, code)
	return code, nil
}

// VerifyOTP checks if the provided code is valid for the email
func VerifyOTP(email, code string) bool {
	otpStore.mu.Lock()
	defer otpStore.mu.Unlock()

	entry, exists := otpStore.store[email]
	if !exists {
		log.Printf("OTP verification failed: no OTP found for %s", email)
		return false
	}

	if time.Now().After(entry.ExpiresAt) {
		delete(otpStore.store, email)
		log.Printf("OTP verification failed: OTP expired for %s", email)
		return false
	}

	if entry.Code != code {
		log.Printf("OTP verification failed: invalid code for %s", email)
		return false
	}

	// OTP is valid, remove it
	delete(otpStore.store, email)
	log.Printf("OTP verified successfully for %s", email)
	return true
}

// CleanupExpiredOTPs removes expired OTPs (run periodically)
func CleanupExpiredOTPs() {
	otpStore.mu.Lock()
	defer otpStore.mu.Unlock()

	now := time.Now()
	for email, entry := range otpStore.store {
		if now.After(entry.ExpiresAt) {
			delete(otpStore.store, email)
		}
	}
}

// StartOTPCleanup starts a background goroutine to clean up expired OTPs
func StartOTPCleanup() {
	go func() {
		ticker := time.NewTicker(60 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			CleanupExpiredOTPs()
		}
	}()
}

func generateRandomCode(length int) (string, error) {
	const digits = "0123456789"
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	for i := range bytes {
		bytes[i] = digits[bytes[i]%10]
	}
	return string(bytes), nil
}

// GetOTPDebug returns the current OTP for debugging (remove in production)
func GetOTPDebug(email string) string {
	otpStore.mu.RLock()
	defer otpStore.mu.RUnlock()
	if entry, exists := otpStore.store[email]; exists {
		return fmt.Sprintf("OTP: %s, Expires in: %v", entry.Code, time.Until(entry.ExpiresAt))
	}
	return "No OTP found"
}
