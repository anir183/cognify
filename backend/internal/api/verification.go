package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"cache-crew/cognify/internal/blockchain"
	"cache-crew/cognify/internal/config"
	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"
	"cache-crew/cognify/internal/services"
)

// VerifyCertificateRequest represents a verification request
type VerifyCertificateRequest struct {
	CertificateHash string `json:"certificateHash"`
	PDFFile         string `json:"pdfFile,omitempty"` // Base64 encoded PDF (future feature)
}

// VerifyCertificateHandler handles public certificate verification
func VerifyCertificateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req VerifyCertificateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
		return
	}

	// Validate hash format
	certHash := strings.TrimSpace(req.CertificateHash)
	if certHash == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Certificate hash is required",
		})
		return
	}

	ctx := r.Context()

	// MOCK MODE: Bypass Blockchain/DB if DB is nil
	if db.FirestoreClient == nil {
		log.Println("[VerifyCertificateHandler] ⚠️ Firestore uninitialized. Returning MOCK verification result.")
		response := models.VerificationResponse{
			Verified:          true,
			StudentName:       "Mock Student",
			CourseName:        "Introduction to Blockchain (Mock)",
			Issuer:            "Cognify University (Mock Mode)",
			WalletAddress:     "0xMockWalletAddress...",
			IssuedAt:          time.Now().Add(-24 * time.Hour),
			BlockchainTx:      "0xMockTransactionHash...",
			TrustScore:        95,
			VerificationCount: 1,
			IPFSPdfLink:       "",
		}
		respondJSON(w, http.StatusOK, response)
		return
	}

	// Step 1: Verify on blockchain (works with both mock and real)
	var onChain bool
	var err error

	if config.AppConfig.BlockchainMode == "real" {
		realClient := blockchain.GetRealClient()
		if realClient != nil {
			onChain, err = realClient.VerifyCertificateHash(certHash)
		} else {
			// Fallback to mock
			mockClient := blockchain.GetMockClient()
			onChain, err = mockClient.VerifyCertificateHash(certHash)
		}
	} else {
		mockClient := blockchain.GetMockClient()
		onChain, err = mockClient.VerifyCertificateHash(certHash)
	}

	if err != nil {
		log.Printf("Blockchain verification error: %v", err)
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Blockchain verification failed",
		})
		return
	}

	// Step 2: Fetch metadata from Firebase
	var cert models.Certificate
	verified := false

	if db.FirestoreClient != nil && onChain {
		doc, err := db.FirestoreClient.Collection("certificates").Doc(certHash).Get(ctx)
		if err == nil {
			if err := doc.DataTo(&cert); err == nil {
				verified = true
			}
		}
	}

	// Step 3: Log verification attempt
	logVerification(ctx, certHash, verified, r.RemoteAddr, r.UserAgent())

	// Step 4: Update verification count and trust score if verified
	if verified {
		trustEngine := services.NewTrustEngine()
		analyticsService := services.NewAnalyticsService()

		// Track Analytics (Async)
		// Get IP and Country (Mocking country for now)
		clientIP := r.Header.Get("X-Forwarded-For")
		if clientIP == "" {
			clientIP = r.RemoteAddr
		}
		country := "UNKNOWN" // In prod use GeoIP

		go analyticsService.TrackVerification(context.Background(), certHash, clientIP, country)

		// Fetch Metrics for Advanced Score
		metric, _ := analyticsService.GetMetrics(ctx, certHash)
		geoCount := 0
		if metric != nil {
			geoCount = len(metric.GeoDistribution)
		}

		// Fetch Issuer Reputation
		var issuerRep *models.IssuerReputation
		if cert.InstructorWallet != "" {
			// Try to find instructor ID/Wallet
			if rep, err := db.FirestoreClient.Collection("issuer_reputation").Doc(cert.InstructorWallet).Get(ctx); err == nil {
				var ir models.IssuerReputation
				rep.DataTo(&ir)
				issuerRep = &ir
			}
		}

		// Calculate Advanced Score
		score, breakdown := trustEngine.CalculateAdvancedScore(ctx, &cert, issuerRep, geoCount)
		cert.TrustScore = score

		// Update Breakdown map for response
		// We'll add this to the response structure

		// Step 5: Build response
		response := models.VerificationResponse{
			Verified:          verified,
			StudentName:       cert.StudentName,
			CourseName:        cert.CourseName,
			Issuer:            "Cognify University",
			WalletAddress:     cert.WalletAddress,
			IssuedAt:          cert.IssuedAt,
			BlockchainTx:      cert.BlockchainTx,
			TrustScore:        score,
			VerificationCount: cert.VerificationCount,
			Revoked:           cert.Revoked,
			TrustLevel:        "Moderate", // Default
		}

		if score >= 90 {
			response.TrustLevel = "Excellent"
		} else if score >= 75 {
			response.TrustLevel = "High"
		}

		// Convert breakdown to map for generic metadata or struct if model updated
		// Using Metadata for flexible breakdown delivery
		response.TrustBreakdown = map[string]int{
			"baseScore":         breakdown.BaseScore,
			"verificationBonus": breakdown.VerificationBonus,
			"longevityBonus":    breakdown.LongevityBonus,
			"issuerReputation":  breakdown.IssuerReputation,
			"geoDiversity":      breakdown.GeoDiversity,
			"blockchainProof":   breakdown.BlockchainProof,
		}

		if cert.IPFSCID != "" {
			response.IPFSPdfLink = "ipfs://" + cert.IPFSCID
		}

		if cert.Revoked {
			response.Message = "⚠️ CERTIFICATE REVOKED"
		}

		respondJSON(w, http.StatusOK, response)
		return
	} else {
		response := models.VerificationResponse{
			Verified: false,
			Message:  "Certificate hash not found in blockchain ledger or database",
		}
		respondJSON(w, http.StatusOK, response)
	}
}

// GetVerificationStatsHandler returns global verification statistics
func GetVerificationStatsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()
	stats := models.VerificationStats{
		TotalIssued:   0,
		TotalVerified: 0,
		FraudAttempts: 0,
	}

	// MOCK MODE CHECK
	if db.FirestoreClient == nil {
		stats.TotalIssued = 1250
		stats.TotalVerified = 3420
		stats.FraudAttempts = 5
		respondJSON(w, http.StatusOK, stats)
		return
	}

	if db.FirestoreClient != nil {
		// Count total certificates issued
		certDocs, err := db.FirestoreClient.Collection("certificates").Documents(ctx).GetAll()
		if err == nil {
			stats.TotalIssued = len(certDocs)
		}

		// Count total verifications
		verifyDocs, err := db.FirestoreClient.Collection("verification_logs").
			Where("verified", "==", true).
			Documents(ctx).GetAll()
		if err == nil {
			stats.TotalVerified = len(verifyDocs)
		}

		// Count fraud attempts (failed verifications)
		fraudDocs, err := db.FirestoreClient.Collection("verification_logs").
			Where("verified", "==", false).
			Documents(ctx).GetAll()
		if err == nil {
			stats.FraudAttempts = len(fraudDocs)
		}
	}

	respondJSON(w, http.StatusOK, stats)
}

// GetCertificateHistoryHandler returns all certificates for a wallet address
// GET /api/certificate/history/{wallet}
func GetCertificateHistoryHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	wallet := r.URL.Query().Get("wallet")
	if wallet == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Wallet address is required",
		})
		return
	}

	// Normalize wallet address
	wallet = strings.ToLower(wallet)

	// MOCK MODE CHECK
	if db.FirestoreClient == nil {
		mockCerts := []models.Certificate{
			{
				ID:            "mock_cert_1",
				Hash:          "0xMockHash123",
				StudentName:   "Student (Mock)",
				CourseName:    "Solidity Fundamentals",
				Marks:         95,
				IssuedAt:      time.Now().Add(-7 * 24 * time.Hour),
				TrustScore:    98,
				WalletAddress: wallet,
			},
			{
				ID:            "mock_cert_2",
				Hash:          "0xMockHash456",
				StudentName:   "Student (Mock)",
				CourseName:    "Advanced React Patterns",
				Marks:         88,
				IssuedAt:      time.Now().Add(-30 * 24 * time.Hour),
				TrustScore:    92,
				WalletAddress: wallet,
			},
		}

		respondJSON(w, http.StatusOK, map[string]interface{}{
			"success":      true,
			"wallet":       wallet,
			"certificates": mockCerts,
			"count":        len(mockCerts),
		})
		return
	}

	ctx := r.Context()
	var certificates []models.Certificate

	if db.FirestoreClient != nil {
		docs, err := db.FirestoreClient.Collection("certificates").
			Where("wallet_address", "==", wallet).
			Documents(ctx).GetAll()

		if err != nil {
			respondJSON(w, http.StatusInternalServerError, map[string]string{
				"error": "Failed to fetch certificate history",
			})
			return
		}

		for _, doc := range docs {
			var cert models.Certificate
			if err := doc.DataTo(&cert); err == nil {
				certificates = append(certificates, cert)
			}
		}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success":      true,
		"wallet":       wallet,
		"certificates": certificates,
		"count":        len(certificates),
	})
}

// logVerification logs a verification attempt to Firestore
func logVerification(ctx context.Context, certHash string, verified bool, ipAddr, userAgent string) {
	if db.FirestoreClient == nil {
		log.Println("[logVerification] ⚠️ Firestore nil. Skipping log.")
		return
	}

	verifyLog := models.VerificationLog{
		CertificateHash: certHash,
		Verified:        verified,
		Timestamp:       time.Now(),
		IPAddress:       ipAddr,
		UserAgent:       userAgent,
	}

	_, err := db.FirestoreClient.Collection("verification_logs").NewDoc().Set(ctx, verifyLog)
	if err != nil {
		log.Printf("Failed to log verification: %v", err)
	}
}
