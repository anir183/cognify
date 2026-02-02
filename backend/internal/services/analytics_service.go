package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"
	"cache-crew/cognify/internal/utils"

	"cloud.google.com/go/firestore"
)

type AnalyticsService struct{}

func NewAnalyticsService() *AnalyticsService {
	return &AnalyticsService{}
}

// GeoIPResponse struct for ip-api.com
type GeoIPResponse struct {
	Status      string `json:"status"`
	CountryCode string `json:"countryCode"`
	Country     string `json:"country"`
}

// resolveCountry performs a simple lookup using ip-api.com
// Note: In a high-scale production, use a local DB (MaxMind) or paid service
func (s *AnalyticsService) resolveCountry(ip string) string {
	// Skip for local/private IPs
	if ip == "127.0.0.1" || ip == "::1" || ip == "localhost" {
		return "LOCAL"
	}

	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(fmt.Sprintf("http://ip-api.com/json/%s", ip))
	if err != nil {
		log.Printf("GeoIP lookup failed for %s: %v", ip, err)
		return "UNKNOWN"
	}
	defer resp.Body.Close()

	var geoResp GeoIPResponse
	if err := json.NewDecoder(resp.Body).Decode(&geoResp); err != nil {
		return "UNKNOWN"
	}

	if geoResp.Status == "success" {
		return geoResp.CountryCode
	}
	return "UNKNOWN"
}

// CheckFraud performs basic velocity checks
func (s *AnalyticsService) CheckFraud(ctx context.Context, ip string) bool {
	// Simple in-memory rate limit check (Mock implementation)
	// In production, use Redis with expiration
	key := "rate_limit:" + ip
	if val, ok := utils.GlobalCache.Get(key); ok {
		count := val.(int)
		if count > 20 { // > 20 verifications in 1 hour is suspicious
			log.Printf("⚠️ FRAUD ALERT: High velocity from IP %s", ip)
			return true
		}
		utils.GlobalCache.Set(key, count+1, 1*time.Hour)
	} else {
		utils.GlobalCache.Set(key, 1, 1*time.Hour)
	}
	return false
}

// TrackVerification updates verification metrics for a certificate
func (s *AnalyticsService) TrackVerification(ctx context.Context, certHash string, ipAddress string, countryCode string) error {
	if db.FirestoreClient == nil {
		return fmt.Errorf("firestore client not initialized")
	}

	// Check Fraud
	isFraud := s.CheckFraud(ctx, ipAddress)
	if isFraud {
		// Log fraud attempt but maybe still allow verification or return error?
		// For now, we just log it and maybe tag the metric
	}

	// Resolve country if not provided or unknown
	if countryCode == "UNKNOWN" || countryCode == "" {
		countryCode = s.resolveCountry(ipAddress)
	}

	docRef := db.FirestoreClient.Collection("verification_metrics").Doc(certHash)

	// Transaction to update metrics atomically
	err := db.FirestoreClient.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(docRef)
		var metric models.VerificationMetric

		if err != nil {
			// Create new if not exists
			metric = models.VerificationMetric{
				CertificateHash:    certHash,
				TotalVerifications: 0,
				UniqueVerifiers:    0,
				GeoDistribution:    make(map[string]int),
				VerificationTrend:  make(map[string]int),
			}
		} else {
			if err := doc.DataTo(&metric); err != nil {
				return err
			}
		}

		// Update fields
		metric.TotalVerifications++
		metric.LastVerifiedAt = time.Now()

		// Geo Distribution
		if metric.GeoDistribution == nil {
			metric.GeoDistribution = make(map[string]int)
		}
		metric.GeoDistribution[countryCode]++

		// Unique Verifiers (Simplistic IP-based estimation)
		// For now, we assume every verification from a new country or day is "unique-ish"
		// In production, use HyperLogLog or Store Unique IP hashes set
		metric.UniqueVerifiers++

		// Update Trend (YYYY-MM)
		monthKey := time.Now().Format("2006-01")
		if metric.VerificationTrend == nil {
			metric.VerificationTrend = make(map[string]int)
		}
		metric.VerificationTrend[monthKey]++

		return tx.Set(docRef, metric)
	})

	if err != nil {
		log.Printf("Failed to track verification analytics: %v", err)
		return err
	}

	return nil
}

// UpdateIssuerReputation recalculates reputation for an instructor
func (s *AnalyticsService) UpdateIssuerReputation(ctx context.Context, instructorID string) error {
	if db.FirestoreClient == nil {
		return nil
	}

	// 1. Get all certificates by this instructor
	certs, err := db.FirestoreClient.Collection("certificates").
		Where("instructor_wallet", "==", instructorID). // assuming ID is wallet for now, or match field
		Documents(ctx).GetAll()

	if err != nil {
		return err
	}

	totalIssued := len(certs)
	if totalIssued == 0 {
		return nil
	}

	revokedCount := 0
	totalTrustScore := 0

	for _, doc := range certs {
		var cert models.Certificate
		doc.DataTo(&cert) // Ignore error
		if cert.Revoked {
			revokedCount++
		}
		totalTrustScore += cert.TrustScore
	}

	avgScore := float64(totalTrustScore) / float64(totalIssued)

	// Reputation Formula (Simple)
	// Base: Avg Trust Score
	// Penalty: Revocation Rate * 100
	revocationRate := float64(revokedCount) / float64(totalIssued)
	reputation := avgScore - (revocationRate * 50.0)

	if reputation < 0 {
		reputation = 0
	}
	if reputation > 100 {
		reputation = 100
	}

	// Update Record
	rep := models.IssuerReputation{
		InstructorID:    instructorID,
		TotalIssued:     totalIssued,
		RevocationCount: revokedCount,
		AvgTrustScore:   avgScore,
		ReputationScore: reputation,
		UpdatedAt:       time.Now(),
	}

	_, err = db.FirestoreClient.Collection("issuer_reputation").Doc(instructorID).Set(ctx, rep)
	return err
}

// GetMetrics retrieves metrics for trust engine
func (s *AnalyticsService) GetMetrics(ctx context.Context, certHash string) (*models.VerificationMetric, error) {
	if db.FirestoreClient == nil {
		return nil, fmt.Errorf("db not connected")
	}

	doc, err := db.FirestoreClient.Collection("verification_metrics").Doc(certHash).Get(ctx)
	if err != nil {
		return nil, err
	}

	var metric models.VerificationMetric
	if err := doc.DataTo(&metric); err != nil {
		return nil, err
	}

	return &metric, nil
}

// SnapshotTrustScore records the current trust score for trending analysis
// Should be called periodically or on significant events to build history
func (s *AnalyticsService) SnapshotTrustScore(ctx context.Context, certHash string, score int, reason string) error {
	if db.FirestoreClient == nil {
		return nil
	}

	event := models.TrustHistoryEvent{
		CertificateHash: certHash,
		Score:           score,
		Reason:          reason,
		Timestamp:       time.Now(),
	}

	// Store in a subcollection for better organization: certificates/{hash}/trust_history
	// Or a top-level collection if we want to query across all certs easily
	// Let's use top-level for now for simpler "global trend" queries if needed later,
	// but partitioned by hash in ID or field.
	_, _, err := db.FirestoreClient.Collection("trust_history").Add(ctx, event)
	return err
}

// GetCertificateRank calculates the percentile of this certificate's score compared to others
// Returns a float between 0.0 and 100.0 (e.g. 95.5 means top 4.5%)
func (s *AnalyticsService) GetCertificateRank(ctx context.Context, score int) (float64, error) {
	if db.FirestoreClient == nil {
		return 0, nil
	}

	// In a real production system with millions of records, DO NOT do this count query every time.
	// You would maintain a histogram or use a counter sharding approach.
	// For this scale, counting is fine.

	col := db.FirestoreClient.Collection("certificates")

	// Count total certificates (cache this in production)
	// Using Select() allows us to get a valid Query object to chain NewAggregationQuery
	q := col.Select() // Select all (empty arg)
	aggQuery := q.NewAggregationQuery().WithCount("total")
	results, err := aggQuery.Get(ctx)
	if err != nil {
		return 0, err
	}

	totalCount := int64(0)
	if val, ok := results["total"]; ok {
		// safe type assertion for firestore count result
		if v, ok := val.(interface{ Integer() int64 }); ok {
			totalCount = v.Integer()
		}
	}

	if totalCount == 0 {
		return 100.0, nil
	}

	// Count certificates with lower score
	qLower := col.Where("trust_score", "<", score)
	aggLower := qLower.NewAggregationQuery().WithCount("lower")
	lowerResults, err := aggLower.Get(ctx)
	if err != nil {
		return 0, err
	}

	lowerCount := int64(0)
	if val, ok := lowerResults["lower"]; ok {
		if v, ok := val.(interface{ Integer() int64 }); ok {
			lowerCount = v.Integer()
		}
	}

	percentile := (float64(lowerCount) / float64(totalCount)) * 100.0
	return percentile, nil
}
