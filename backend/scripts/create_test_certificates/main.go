package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"time"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

type TestCertificate struct {
	Hash              string    `firestore:"hash"`
	StudentID         string    `firestore:"student_id"`
	StudentName       string    `firestore:"student_name"`
	CourseName        string    `firestore:"course_name"`
	Marks             float64   `firestore:"marks"`
	WalletAddress     string    `firestore:"wallet_address"`
	InstructorWallet  string    `firestore:"instructor_wallet"`
	InstructorName    string    `firestore:"instructor_name"`
	BlockchainTx      string    `firestore:"blockchain_tx"`
	IPFSCID           string    `firestore:"ipfs_cid"`
	TrustScore        int       `firestore:"trust_score"`
	VerificationCount int       `firestore:"verification_count"`
	Revoked           bool      `firestore:"revoked"`
	IssuedAt          time.Time `firestore:"issuedAt"`
	AcademicDNA       string    `firestore:"academic_dna"`
}

func main() {
	ctx := context.Background()

	// Initialize Firebase
	opt := option.WithCredentialsFile("../../serviceAccountKey.json")
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Fatalf("Error initializing Firebase: %v", err)
	}

	client, err := app.Firestore(ctx)
	if err != nil {
		log.Fatalf("Error initializing Firestore: %v", err)
	}
	defer client.Close()

	// Create test certificates
	certificates := []TestCertificate{
		{
			StudentID:         "STU001",
			StudentName:       "Alice Johnson",
			CourseName:        "Blockchain Fundamentals",
			Marks:             95.5,
			WalletAddress:     "0xalice123456789abcdef",
			InstructorWallet:  "0xinstructor001",
			InstructorName:    "Dr. Smith",
			BlockchainTx:      "0xtx123456789abcdef",
			IPFSCID:           "QmTest123",
			TrustScore:        85,
			VerificationCount: 15,
			Revoked:           false,
			IssuedAt:          time.Now().Add(-180 * 24 * time.Hour), // 6 months ago
			AcademicDNA:       generateAcademicDNA("STU001", "Alice Johnson"),
		},
		{
			StudentID:         "STU002",
			StudentName:       "Bob Williams",
			CourseName:        "Smart Contract Development",
			Marks:             88.0,
			WalletAddress:     "0xbob123456789abcdef",
			InstructorWallet:  "0xinstructor001",
			InstructorName:    "Dr. Smith",
			BlockchainTx:      "0xtx987654321fedcba",
			IPFSCID:           "QmTest456",
			TrustScore:        78,
			VerificationCount: 8,
			Revoked:           false,
			IssuedAt:          time.Now().Add(-90 * 24 * time.Hour), // 3 months ago
			AcademicDNA:       generateAcademicDNA("STU002", "Bob Williams"),
		},
		{
			StudentID:         "STU003",
			StudentName:       "Carol Davis",
			CourseName:        "Web3 Development",
			Marks:             92.5,
			WalletAddress:     "0xcarol123456789abcdef",
			InstructorWallet:  "0xinstructor002",
			InstructorName:    "Prof. Johnson",
			BlockchainTx:      "0xtxaabbccddeeff",
			IPFSCID:           "QmTest789",
			TrustScore:        90,
			VerificationCount: 25,
			Revoked:           false,
			IssuedAt:          time.Now().Add(-365 * 24 * time.Hour), // 1 year ago
			AcademicDNA:       generateAcademicDNA("STU003", "Carol Davis"),
		},
	}

	// Insert certificates
	for i, cert := range certificates {
		// Generate hash
		hashData := fmt.Sprintf("%s-%s-%s-%f-%d", cert.StudentID, cert.CourseName, cert.InstructorWallet, cert.Marks, cert.IssuedAt.Unix())
		hash := sha256.Sum256([]byte(hashData))
		cert.Hash = "0x" + hex.EncodeToString(hash[:])

		// Save to Firestore
		_, err := client.Collection("certificates").Doc(cert.Hash).Set(ctx, cert)
		if err != nil {
			log.Printf("Error creating certificate %d: %v", i+1, err)
		} else {
			log.Printf("✅ Created certificate %d: %s (Hash: %s)", i+1, cert.StudentName, cert.Hash[:16]+"...")
		}
	}

	// Create verification metrics for the first certificate
	cert1Hash := certificates[0].Hash
	verificationMetric := map[string]interface{}{
		"certificate_hash":    cert1Hash,
		"total_verifications": 15,
		"unique_verifiers":    12,
		"geo_distribution": map[string]int{
			"US": 5,
			"IN": 6,
			"UK": 3,
			"CA": 1,
		},
		"last_verified_at": time.Now(),
		"verification_trend": map[string]int{
			"2026-01": 15,
		},
	}

	_, err = client.Collection("verification_metrics").Doc(cert1Hash).Set(ctx, verificationMetric)
	if err != nil {
		log.Printf("Error creating verification metrics: %v", err)
	} else {
		log.Printf("✅ Created verification metrics for certificate 1")
	}

	// Create issuer reputation for instructor 1
	issuerRep := map[string]interface{}{
		"instructor_id":    "0xinstructor001",
		"total_issued":     2,
		"revocation_count": 0,
		"avg_trust_score":  81.5,
		"reputation_score": 81.5,
		"updated_at":       time.Now(),
	}

	_, err = client.Collection("issuer_reputation").Doc("0xinstructor001").Set(ctx, issuerRep)
	if err != nil {
		log.Printf("Error creating issuer reputation: %v", err)
	} else {
		log.Printf("✅ Created issuer reputation for instructor 1")
	}

	log.Println("\n🎉 Test data created successfully!")
	log.Printf("\nYou can now test with certificate hash: %s", certificates[0].Hash)
}

func generateAcademicDNA(studentID, studentName string) string {
	data := fmt.Sprintf("%s-%s-%d", studentID, studentName, time.Now().Unix())
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:8])
}
