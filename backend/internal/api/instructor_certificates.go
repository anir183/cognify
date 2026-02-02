package api

import (
	"context"
	"log"
	"net/http"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/iterator"
)

// GetInstructorCertificatesHandler returns all certificates issued by an instructor
func GetInstructorCertificatesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get instructor wallet from query params
	instructorWallet := r.URL.Query().Get("wallet")
	if instructorWallet == "" {
		respondJSON(w, http.StatusBadRequest, map[string]interface{}{
			"success": false,
			"error":   "Instructor wallet address is required",
		})
		return
	}

	ctx := r.Context()

	// MOCK MODE: Return mock data if Firestore is not available
	if db.FirestoreClient == nil {
		log.Println("MOCK MODE: Returning mock instructor certificates")
		mockCerts := []map[string]interface{}{
			{
				"hash":              "mock_cert_hash_001",
				"studentName":       "Alice Johnson",
				"courseName":        "Introduction to Blockchain",
				"marks":             95.5,
				"issuedAt":          "2024-01-15T10:30:00Z",
				"walletAddress":     "0x1234...5678",
				"instructorWallet":  instructorWallet,
				"trustScore":        85,
				"verificationCount": 5,
			},
			{
				"hash":              "mock_cert_hash_002",
				"studentName":       "Bob Smith",
				"courseName":        "Advanced Smart Contracts",
				"marks":             88.0,
				"issuedAt":          "2024-01-20T14:15:00Z",
				"walletAddress":     "0x9876...4321",
				"instructorWallet":  instructorWallet,
				"trustScore":        78,
				"verificationCount": 3,
			},
		}

		respondJSON(w, http.StatusOK, map[string]interface{}{
			"success":      true,
			"certificates": mockCerts,
			"count":        len(mockCerts),
			"mode":         "mock",
		})
		return
	}

	// Query certificates by instructor wallet
	certificates := []models.Certificate{}
	iter := db.FirestoreClient.Collection("certificates").
		Where("instructorWallet", "==", instructorWallet).
		OrderBy("issuedAt", firestore.Desc).
		Documents(ctx)

	defer iter.Stop()

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Printf("Error iterating certificates: %v", err)
			respondJSON(w, http.StatusInternalServerError, map[string]interface{}{
				"success": false,
				"error":   "Failed to fetch certificates",
			})
			return
		}

		var cert models.Certificate
		if err := doc.DataTo(&cert); err != nil {
			log.Printf("Error parsing certificate: %v", err)
			continue
		}

		certificates = append(certificates, cert)
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success":      true,
		"certificates": certificates,
		"count":        len(certificates),
	})
}

// GetInstructorStatsHandler returns statistics for an instructor
func GetInstructorStatsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	instructorWallet := r.URL.Query().Get("wallet")
	if instructorWallet == "" {
		respondJSON(w, http.StatusBadRequest, map[string]interface{}{
			"success": false,
			"error":   "Instructor wallet address is required",
		})
		return
	}

	ctx := context.Background()

	// MOCK MODE
	if db.FirestoreClient == nil {
		log.Println("MOCK MODE: Returning mock instructor stats")
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"success":            true,
			"certificatesIssued": 42,
			"totalStudents":      38,
			"averageTrustScore":  82.5,
			"totalVerifications": 156,
			"mode":               "mock",
		})
		return
	}

	// Count certificates issued by this instructor
	iter := db.FirestoreClient.Collection("certificates").
		Where("instructorWallet", "==", instructorWallet).
		Documents(ctx)

	defer iter.Stop()

	count := 0
	totalTrustScore := 0.0
	totalVerifications := 0
	uniqueStudents := make(map[string]bool)

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Printf("Error counting certificates: %v", err)
			break
		}

		var cert models.Certificate
		if err := doc.DataTo(&cert); err == nil {
			count++
			totalTrustScore += float64(cert.TrustScore)
			totalVerifications += cert.VerificationCount
			uniqueStudents[cert.StudentID] = true
		}
	}

	avgTrustScore := 0.0
	if count > 0 {
		avgTrustScore = totalTrustScore / float64(count)
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success":            true,
		"certificatesIssued": count,
		"totalStudents":      len(uniqueStudents),
		"averageTrustScore":  avgTrustScore,
		"totalVerifications": totalVerifications,
	})
}
