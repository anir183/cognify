package api

import (
	"context"
	"net/http"
	"strings"
	"time"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"
	"cache-crew/cognify/internal/services"
	"cache-crew/cognify/internal/utils"
)

// TrustAnalyticsResponse contains aggregated trust intelligence data
type TrustAnalyticsResponse struct {
	CertificateHash    string                       `json:"certificateHash"`
	TrustScore         int                          `json:"trustScore"`
	TrustLevel         string                       `json:"trustLevel"`
	TrustBreakdown     services.TrustScoreBreakdown `json:"trustBreakdown"`
	VerificationMetric *models.VerificationMetric   `json:"verificationMetric,omitempty"`
	IssuerReputation   *models.IssuerReputation     `json:"issuerReputation,omitempty"`
	Percentile         float64                      `json:"percentile"` // Peer benchmarking (0-100)
}

// InstructorAnalyticsResponse contains instructor-specific analytics
type InstructorAnalyticsResponse struct {
	InstructorID       string                   `json:"instructorId"`
	Reputation         *models.IssuerReputation `json:"reputation"`
	TotalCertificates  int                      `json:"totalCertificates"`
	ActiveCertificates int                      `json:"activeCertificates"`
	RevokedCount       int                      `json:"revokedCount"`
	AverageTrustScore  float64                  `json:"averageTrustScore"`
	TopCertificates    []CertificateSummary     `json:"topCertificates"`
}

// CertificateSummary is a lightweight certificate representation
type CertificateSummary struct {
	Hash          string `json:"hash"`
	StudentName   string `json:"studentName"`
	CourseName    string `json:"courseName"`
	TrustScore    int    `json:"trustScore"`
	Verifications int    `json:"verifications"`
}

// GetTrustAnalyticsHandler returns detailed trust analytics for a certificate
// GET /api/analytics/trust/{hash}
func GetTrustAnalyticsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract hash from URL
	hash := r.URL.Query().Get("hash")
	if hash == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Certificate hash is required",
		})
		return
	}

	// Check Cache (5 minutes TTL)
	cacheKey := "trust_analytics:" + hash
	if cachedVal, ok := utils.GlobalCache.Get(cacheKey); ok {
		respondJSON(w, http.StatusOK, cachedVal)
		return
	}

	ctx := r.Context()

	// Check DB availability
	if db.FirestoreClient == nil {
		respondJSON(w, http.StatusServiceUnavailable, map[string]string{
			"error": "Database unavailable",
		})
		return
	}

	// Fetch certificate
	doc, err := db.FirestoreClient.Collection("certificates").Doc(hash).Get(ctx)
	if err != nil {
		respondJSON(w, http.StatusNotFound, map[string]string{
			"error": "Certificate not found",
		})
		return
	}

	var cert models.Certificate
	if err := doc.DataTo(&cert); err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to parse certificate",
		})
		return
	}

	// Initialize services
	trustEngine := services.NewTrustEngine()
	analyticsService := services.NewAnalyticsService()

	// Fetch verification metrics
	metric, _ := analyticsService.GetMetrics(ctx, hash)
	geoCount := 0
	if metric != nil {
		geoCount = len(metric.GeoDistribution)
	}

	// Fetch issuer reputation
	var issuerRep *models.IssuerReputation
	if cert.InstructorWallet != "" {
		if repDoc, err := db.FirestoreClient.Collection("issuer_reputation").Doc(cert.InstructorWallet).Get(ctx); err == nil {
			var ir models.IssuerReputation
			repDoc.DataTo(&ir)
			issuerRep = &ir
		}
	}

	// Calculate advanced score
	score, breakdown := trustEngine.CalculateAdvancedScore(ctx, &cert, issuerRep, geoCount)

	// Async: Snapshot history (fire and forget to avoid latency)
	go func() {
		// Create a detached context for the async operation
		bgCtx := context.Background()
		if err := analyticsService.SnapshotTrustScore(bgCtx, hash, score, "verification"); err != nil {
			// output to stdout/log is enough
		}
	}()

	// Calculate Percentile (Benchmarking)
	percentile, _ := analyticsService.GetCertificateRank(ctx, score)

	// Determine trust level
	level := "Moderate"
	if score >= 90 {
		level = "Excellent"
	} else if score >= 75 {
		level = "High"
	} else if score < 50 {
		level = "Low"
	}

	// Build response
	response := TrustAnalyticsResponse{
		CertificateHash:    hash,
		TrustScore:         score,
		TrustLevel:         level,
		TrustBreakdown:     breakdown,
		VerificationMetric: metric,
		IssuerReputation:   issuerRep,
		Percentile:         percentile,
	}

	// Cache the result
	utils.GlobalCache.Set(cacheKey, response, 5*time.Minute)

	respondJSON(w, http.StatusOK, response)
}

// GetInstructorAnalyticsHandler returns analytics for an instructor
// GET /api/analytics/instructor/{wallet}
func GetInstructorAnalyticsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract wallet from URL
	wallet := r.URL.Query().Get("wallet")
	if wallet == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Instructor wallet address is required",
		})
		return
	}

	wallet = strings.ToLower(wallet)
	ctx := r.Context()

	// Check DB availability
	if db.FirestoreClient == nil {
		respondJSON(w, http.StatusServiceUnavailable, map[string]string{
			"error": "Database unavailable",
		})
		return
	}

	// Fetch instructor reputation
	var reputation *models.IssuerReputation
	if repDoc, err := db.FirestoreClient.Collection("issuer_reputation").Doc(wallet).Get(ctx); err == nil {
		var ir models.IssuerReputation
		repDoc.DataTo(&ir)
		reputation = &ir
	}

	// Fetch all certificates by this instructor
	docs, err := db.FirestoreClient.Collection("certificates").
		Where("instructor_wallet", "==", wallet).
		Documents(ctx).GetAll()

	if err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to fetch certificates",
		})
		return
	}

	// Calculate statistics
	totalCerts := len(docs)
	activeCerts := 0
	revokedCount := 0
	totalTrustScore := 0
	topCerts := []CertificateSummary{}

	for _, doc := range docs {
		var cert models.Certificate
		doc.DataTo(&cert)

		if cert.Revoked {
			revokedCount++
		} else {
			activeCerts++
		}

		totalTrustScore += cert.TrustScore

		// Collect top certificates (for now, just first 5)
		if len(topCerts) < 5 {
			topCerts = append(topCerts, CertificateSummary{
				Hash:          cert.Hash,
				StudentName:   cert.StudentName,
				CourseName:    cert.CourseName,
				TrustScore:    cert.TrustScore,
				Verifications: cert.VerificationCount,
			})
		}
	}

	avgTrustScore := 0.0
	if totalCerts > 0 {
		avgTrustScore = float64(totalTrustScore) / float64(totalCerts)
	}

	// Build response
	response := InstructorAnalyticsResponse{
		InstructorID:       wallet,
		Reputation:         reputation,
		TotalCertificates:  totalCerts,
		ActiveCertificates: activeCerts,
		RevokedCount:       revokedCount,
		AverageTrustScore:  avgTrustScore,
		TopCertificates:    topCerts,
	}

	respondJSON(w, http.StatusOK, response)
}

// UpdateInstructorReputationHandler triggers reputation recalculation
// POST /api/analytics/instructor/{wallet}/update-reputation
func UpdateInstructorReputationHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract wallet from URL
	wallet := r.URL.Query().Get("wallet")
	if wallet == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Instructor wallet address is required",
		})
		return
	}

	wallet = strings.ToLower(wallet)
	ctx := r.Context()

	// Check DB availability
	if db.FirestoreClient == nil {
		respondJSON(w, http.StatusServiceUnavailable, map[string]string{
			"error": "Database unavailable",
		})
		return
	}

	// Trigger reputation update
	analyticsService := services.NewAnalyticsService()
	if err := analyticsService.UpdateIssuerReputation(ctx, wallet); err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to update reputation",
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Reputation updated successfully",
	})
}
