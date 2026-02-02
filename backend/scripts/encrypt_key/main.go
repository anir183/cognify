package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"syscall"

	"cache-crew/cognify/internal/utils"

	"golang.org/x/term"
)

func main() {
	fmt.Println("🔐 Private Key Encryption Utility")
	fmt.Println("==================================\n")

	reader := bufio.NewReader(os.Stdin)

	// Get private key
	fmt.Print("Enter your private key (without 0x prefix): ")
	privateKey, _ := reader.ReadString('\n')
	privateKey = strings.TrimSpace(privateKey)

	if privateKey == "" {
		fmt.Println("❌ Private key cannot be empty")
		os.Exit(1)
	}

	// Remove 0x prefix if present
	privateKey = strings.TrimPrefix(privateKey, "0x")

	// Validate length (should be 64 characters for ECDSA)
	if len(privateKey) != 64 {
		fmt.Printf("⚠️  Warning: Private key should be 64 characters, got %d\n", len(privateKey))
	}

	// Get passphrase
	fmt.Print("Enter encryption passphrase: ")
	passphrase, err := term.ReadPassword(int(syscall.Stdin))
	if err != nil {
		fmt.Println("\n❌ Failed to read passphrase:", err)
		os.Exit(1)
	}
	fmt.Println()

	if len(passphrase) < 8 {
		fmt.Println("❌ Passphrase must be at least 8 characters")
		os.Exit(1)
	}

	// Confirm passphrase
	fmt.Print("Confirm passphrase: ")
	confirmPass, err := term.ReadPassword(int(syscall.Stdin))
	if err != nil {
		fmt.Println("\n❌ Failed to read confirmation:", err)
		os.Exit(1)
	}
	fmt.Println()

	if string(passphrase) != string(confirmPass) {
		fmt.Println("❌ Passphrases do not match")
		os.Exit(1)
	}

	// Encrypt
	fmt.Println("\n🔄 Encrypting private key...")
	encrypted, err := utils.EncryptPrivateKey(privateKey, string(passphrase))
	if err != nil {
		fmt.Println("❌ Encryption failed:", err)
		os.Exit(1)
	}

	// Test decryption
	fmt.Println("🔄 Verifying encryption...")
	decrypted, err := utils.DecryptPrivateKey(encrypted, string(passphrase))
	if err != nil {
		fmt.Println("❌ Verification failed:", err)
		os.Exit(1)
	}

	if decrypted != privateKey {
		fmt.Println("❌ Decryption mismatch!")
		os.Exit(1)
	}

	// Success
	fmt.Println("✅ Encryption successful!\n")
	fmt.Println("Add these to your .env file:")
	fmt.Println("=============================")
	fmt.Printf("PRIVATE_KEY_ENCRYPTED=%s\n", encrypted)
	fmt.Printf("ENCRYPTION_PASSPHRASE=%s\n", string(passphrase))
	fmt.Println("=============================\n")
	fmt.Println("⚠️  IMPORTANT:")
	fmt.Println("   - Never commit these values to Git")
	fmt.Println("   - Store passphrase securely (password manager)")
	fmt.Println("   - Keep backup of encrypted key")
	fmt.Println("   - Use different keys for testnet and mainnet")
}
