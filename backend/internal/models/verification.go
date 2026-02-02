package models

import "time"

// VerificationLog tracks certificate verification attempts
type VerificationLog struct {
	CertificateHash string    `firestore:"certificate_hash" json:"certificateHash"`
	Verified        bool      `firestore:"verified" json:"verified"`
	Timestamp       time.Time `firestore:"timestamp" json:"timestamp"`
	IPAddress       string    `firestore:"ip_address" json:"ipAddress"`
	UserAgent       string    `firestore:"user_agent,omitempty" json:"userAgent,omitempty"`
}

// VerificationResponse is the API response for certificate verification
type VerificationResponse struct {
	Verified          bool           `json:"verified"`
	StudentName       string         `json:"studentName,omitempty"`
	CourseName        string         `json:"courseName,omitempty"`
	Issuer            string         `json:"issuer,omitempty"`
	WalletAddress     string         `json:"walletAddress,omitempty"`
	IssuedAt          time.Time      `json:"issuedAt,omitempty"`
	BlockchainTx      string         `json:"blockchainTx,omitempty"`
	TrustScore        int            `json:"trustScore,omitempty"`
	TrustLevel        string         `json:"trustLevel,omitempty"`     // NEW
	TrustBreakdown    map[string]int `json:"trustBreakdown,omitempty"` // NEW
	IPFSPdfLink       string         `json:"ipfsPdfLink,omitempty"`
	VerificationCount int            `json:"verificationCount,omitempty"`
	Revoked           bool           `json:"revoked,omitempty"`
	Message           string         `json:"message,omitempty"`
}

// VerificationStats represents global verification statistics
type VerificationStats struct {
	TotalIssued   int `json:"totalIssued"`
	TotalVerified int `json:"totalVerified"`
	FraudAttempts int `json:"fraudAttempts"`
}
