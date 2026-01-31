package services

import (
	"context"
	"fmt"
	"log"
	"math"
	"time"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"
)

// TrustEngine calculates and manages certificate trust scores
type TrustEngine struct{}

// NewTrustEngine creates a new trust engine instance
func NewTrustEngine() *TrustEngine {
	return &TrustEngine{}
}

// TrustScoreBreakdown provides details on how the score was calculated
type TrustScoreBreakdown struct {
	BaseScore         int `json:"baseScore"`
	VerificationBonus int `json:"verificationBonus"`
	LongevityBonus    int `json:"longevityBonus"`
	IssuerReputation  int `json:"issuerReputation"`
	GeoDiversity      int `json:"geoDiversity"`
	BlockchainProof   int `json:"blockchainProof"`
	TotalScore        int `json:"totalScore"`
}

// CalculateAdvancedScore computes a comprehensive trust score
func (te *TrustEngine) CalculateAdvancedScore(ctx context.Context, cert *models.Certificate, issuerRep *models.IssuerReputation, geoCount int) (int, TrustScoreBreakdown) {
	breakdown := TrustScoreBreakdown{
		BaseScore: 50,
	}
	score := float64(breakdown.BaseScore)

	// 1. Verification Frequency (Logarithmic scale, max 20)
	// rewards early verifications heavily, diminishes later
	vBonus := math.Min(20, math.Log2(float64(cert.VerificationCount+1))*5)
	breakdown.VerificationBonus = int(vBonus)
	score += vBonus

	// 2. Longevity / Time Decay (Max 10)
	// Reward certificates that have stood the test of time (older > 6 months = stable)
	daysSinceIssue := time.Since(cert.IssuedAt).Hours() / 24
	lBonus := 0.0
	if daysSinceIssue > 180 {
		lBonus = 10 // Trusted because it hasn't been revoked for 6 months
	} else if daysSinceIssue > 30 {
		lBonus = 5
	}
	breakdown.LongevityBonus = int(lBonus)
	score += lBonus

	// 3. Issuer Reputation (Max 15)
	// If issuer has high reputation score, pass it on
	iBonus := 0.0
	if issuerRep != nil && issuerRep.ReputationScore > 0 {
		// Map 0-100 reputation to 0-15 bonus
		iBonus = (issuerRep.ReputationScore / 100.0) * 15.0
	} else {
		// Default bonus for unknown issuers if not revoked
		iBonus = 5.0
	}
	breakdown.IssuerReputation = int(iBonus)
	score += iBonus

	// 4. Geo Diversity (Max 10)
	// Verified from multiple countries?
	gBonus := math.Min(10, float64(geoCount)*2)
	breakdown.GeoDiversity = int(gBonus)
	score += gBonus

	// 5. Blockchain Proof (Fixed 15)
	if cert.BlockchainTx != "" {
		breakdown.BlockchainProof = 15
		score += 15
	}

	// 6. Penalty for Revocation (nuclear option)
	if cert.Revoked {
		score = 0
	} else {
		// Cap at 100
		if score > 100 {
			score = 100
		}
	}

	breakdown.TotalScore = int(score)
	return int(score), breakdown
}

// CalculateTrustScore computes a basic 0-100 trust score (Legacy Wrapper)
func (te *TrustEngine) CalculateTrustScore(ctx context.Context, cert *models.Certificate) int {
	// Simple wrapper for backward compatibility
	score, _ := te.CalculateAdvancedScore(ctx, cert, nil, 0)
	return score
}

// DetectFraud performs basic fraud detection checks
func (te *TrustEngine) DetectFraud(ctx context.Context, certHash string, metadata map[string]interface{}) bool {
	// TODO: Implement AI-based fraud detection
	// For now, basic heuristics:

	// Check for suspicious patterns in verification logs
	if db.FirestoreClient != nil {
		// Query verification logs for this certificate
		docs, err := db.FirestoreClient.Collection("verification_logs").
			Where("certificate_hash", "==", certHash).
			Limit(100).
			Documents(ctx).
			GetAll()

		if err == nil && len(docs) > 50 {
			// Too many verifications in short time could be suspicious
			log.Printf("⚠️ High verification count for certificate: %s", certHash[:16]+"...")
			return true
		}
	}

	return false
}

// GetReputationMetrics generates reputation data for employers
func (te *TrustEngine) GetReputationMetrics(ctx context.Context, certHash string) map[string]interface{} {
	metrics := map[string]interface{}{
		"certificateHash": certHash,
		"trustLevel":      "High",
		"verifiedBy":      "Cognify Platform",
		"blockchainProof": true,
	}

	// Fetch verification count
	if db.FirestoreClient != nil {
		doc, err := db.FirestoreClient.Collection("certificates").Doc(certHash).Get(ctx)
		if err == nil {
			var cert models.Certificate
			if err := doc.DataTo(&cert); err == nil {
				metrics["verificationCount"] = cert.VerificationCount
				metrics["trustScore"] = cert.TrustScore
				metrics["issuedAt"] = cert.IssuedAt
			}
		}
	}

	return metrics
}

// IncrementVerificationCount updates the verification count for a certificate
func (te *TrustEngine) IncrementVerificationCount(ctx context.Context, certHash string) error {
	if db.FirestoreClient == nil {
		return fmt.Errorf("firestore client not initialized")
	}

	docRef := db.FirestoreClient.Collection("certificates").Doc(certHash)

	// Get current certificate
	doc, err := docRef.Get(ctx)
	if err != nil {
		return err
	}

	var cert models.Certificate
	if err := doc.DataTo(&cert); err != nil {
		return err
	}

	// Increment count
	cert.VerificationCount++

	// Recalculate trust score
	cert.TrustScore = te.CalculateTrustScore(ctx, &cert)

	// Update in Firestore
	_, err = docRef.Set(ctx, cert)
	return err
}
