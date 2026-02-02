package models

// MetaMaskAuthRequest represents the authentication request from MetaMask
type MetaMaskAuthRequest struct {
	WalletAddress string `json:"walletAddress"`
	Signature     string `json:"signature"`
	Message       string `json:"message"`
	StudentName   string `json:"studentName,omitempty"`
	Email         string `json:"email,omitempty"`
	Role          string `json:"role,omitempty"` // "student" or "instructor"
}

// MetaMaskAuthResponse represents the authentication response
type MetaMaskAuthResponse struct {
	Success       bool   `json:"success"`
	WalletAddress string `json:"walletAddress"`
	Token         string `json:"token,omitempty"`
	User          User   `json:"user"`
	IsNewUser     bool   `json:"isNewUser"`
	AcademicDNA   string `json:"academicDNA,omitempty"`
}
