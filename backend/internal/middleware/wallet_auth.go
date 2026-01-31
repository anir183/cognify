package middleware

import (
	"cache-crew/cognify/internal/db"
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
)

// VerifySignature verifies an Ethereum signature against a message and address
// This implements EIP-191 personal_sign standard
func VerifySignature(message, signature, address string) (bool, error) {
	// Construct the Ethereum signed message prefix
	prefix := fmt.Sprintf("\x19Ethereum Signed Message:\n%d", len(message))
	prefixedMessage := prefix + message

	// Hash the prefixed message
	hash := crypto.Keccak256Hash([]byte(prefixedMessage))

	// Decode the signature from hex
	sig, err := hexutil.Decode(signature)
	if err != nil {
		return false, fmt.Errorf("failed to decode signature: %w", err)
	}

	// Ethereum signatures have a recovery ID (v) at the end
	// go-ethereum expects v to be 0 or 1, but MetaMask returns 27 or 28
	if len(sig) == 65 && (sig[64] == 27 || sig[64] == 28) {
		sig[64] -= 27
	}

	// Recover the public key from the signature
	pubKey, err := crypto.SigToPub(hash.Bytes(), sig)
	if err != nil {
		log.Printf("[VerifySignature] Failed to recover pubkey: %v", err)
		return false, fmt.Errorf("failed to recover public key: %w", err)
	}

	// Derive the address from the public key
	recoveredAddr := crypto.PubkeyToAddress(*pubKey)

	// Log for debugging
	log.Printf("[VerifySignature] Message: %s", message)
	log.Printf("[VerifySignature] Prefixed: %q", prefixedMessage)
	log.Printf("[VerifySignature] Recov Addr: %s", recoveredAddr.Hex())
	log.Printf("[VerifySignature] Expect Addr: %s", address)

	// Compare addresses (case-insensitive)
	return strings.EqualFold(recoveredAddr.Hex(), address), nil
}

// WalletAuthMiddleware validates wallet signature in request headers
// Expected headers:
// - X-Wallet-Address: Ethereum address (0x...)
// - X-Wallet-Signature: Signed message signature
// - X-Signed-Message: Original message that was signed
func WalletAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract authentication headers
		signature := r.Header.Get("X-Wallet-Signature")
		wallet := r.Header.Get("X-Wallet-Address")
		message := r.Header.Get("X-Signed-Message")

		// Validate required headers
		if signature == "" || wallet == "" || message == "" {
			http.Error(w, `{"error":"Missing wallet authentication headers"}`, http.StatusUnauthorized)
			w.Header().Set("Content-Type", "application/json")
			return
		}

		// Verify the signature
		valid, err := VerifySignature(message, signature, wallet)
		if err != nil {
			http.Error(w, fmt.Sprintf(`{"error":"Signature verification failed: %s"}`, err.Error()), http.StatusUnauthorized)
			w.Header().Set("Content-Type", "application/json")
			return
		}

		if !valid {
			http.Error(w, `{"error":"Invalid signature"}`, http.StatusUnauthorized)
			w.Header().Set("Content-Type", "application/json")
			return
		}

		// Add wallet address to request context
		ctx := context.WithValue(r.Context(), "wallet", wallet)

		// Fetch user from DB to get role
		// Fetch user from DB to get role
		if db.FirestoreClient != nil {
			// QUERY by walletAddress field, do not assume Doc ID is wallet
			// Ensure wallet is lowercase to match storage
			walletLower := strings.ToLower(wallet)
			iter := db.FirestoreClient.Collection("users").Where("walletAddress", "==", walletLower).Documents(r.Context())
			snap, err := iter.Next() // Get first match

			if err != nil {
				// Log error but allow request to proceed (role check will fail downstream if needed)
				log.Printf("WalletAuthMiddleware: Could not find user with wallet %s: %v", wallet, err)
			} else {
				data := snap.Data()
				if role, ok := data["Role"].(string); ok {
					ctx = context.WithValue(ctx, "role", role)

					// If instructor, authorized check
					if role == "instructor" {
						ctx = context.WithValue(ctx, "is_authorized", true)
					}
				}
			}
		} else {
			// Mock Mode Fallback - For Dev/Audit
			log.Println("WalletAuthMiddleware: DB client not available, ensuring role for audit")
			ctx = context.WithValue(ctx, "role", "instructor")
			ctx = context.WithValue(ctx, "is_authorized", true)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// GetWalletFromContext retrieves the authenticated wallet address from context
func GetWalletFromContext(ctx context.Context) (string, bool) {
	wallet, ok := ctx.Value("wallet").(string)
	return wallet, ok
}
