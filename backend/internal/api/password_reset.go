package api

import (
	"encoding/json"
	"net/http"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"
	"cache-crew/cognify/internal/services"

	"cloud.google.com/go/firestore"
	"golang.org/x/crypto/bcrypt"
)

// ForgotPasswordRequest represents the forgot password request body
type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

// ResetPasswordRequest represents the reset password request body
type ResetPasswordRequest struct {
	Email       string `json:"email"`
	NewPassword string `json:"newPassword"`
}

// ForgotPasswordHandler handles the forgot password request (sends OTP)
func ForgotPasswordHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ForgotPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Invalid request body",
		})
		return
	}

	if req.Email == "" {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Email is required",
		})
		return
	}

	// Check if user exists
	doc, err := db.FirestoreClient.Collection("users").Doc(req.Email).Get(r.Context())
	if err != nil || !doc.Exists() {
		respondJSON(w, http.StatusNotFound, map[string]interface{}{
			"success":      false,
			"message":      "Email not registered. Please sign up first.",
			"shouldSignup": true,
		})
		return
	}

	// Generate OTP
	otp, err := services.GenerateOTP(req.Email)
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "Failed to generate OTP",
		})
		return
	}

	// Send OTP via email
	if err := services.SendOTPEmail(req.Email, otp); err != nil {
		respondJSON(w, http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "Failed to send OTP email",
		})
		return
	}

	respondJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		Message: "OTP sent to your email. Please check your inbox.",
	})
}

// VerifyResetOTPHandler verifies OTP for password reset (doesn't complete login)
func VerifyResetOTPHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req VerifyOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Invalid request body",
		})
		return
	}

	if req.Email == "" || req.Code == "" {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Email and OTP code are required",
		})
		return
	}

	// Verify OTP
	if !services.VerifyOTP(req.Email, req.Code) {
		respondJSON(w, http.StatusUnauthorized, AuthResponse{
			Success: false,
			Message: "Invalid or expired OTP",
		})
		return
	}

	// OTP verified - generate a temporary reset token for security
	// For simplicity, we'll just return success and expect the next call to include email
	// In production, you'd generate a short-lived JWT or session token here
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "OTP verified. You can now reset your password.",
		"email":   req.Email,
	})
}

// ResetPasswordHandler handles the password reset
func ResetPasswordHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Invalid request body",
		})
		return
	}

	if req.Email == "" || req.NewPassword == "" {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Email and new password are required",
		})
		return
	}

	if len(req.NewPassword) < 6 {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Password must be at least 6 characters",
		})
		return
	}

	// Check if user exists
	doc, err := db.FirestoreClient.Collection("users").Doc(req.Email).Get(r.Context())
	if err != nil || !doc.Exists() {
		respondJSON(w, http.StatusNotFound, AuthResponse{
			Success: false,
			Message: "User not found",
		})
		return
	}

	// Get existing user data
	var user models.User
	if err := doc.DataTo(&user); err != nil {
		respondJSON(w, http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "Database error",
		})
		return
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "Failed to secure password",
		})
		return
	}

	// Update password in database
	_, err = db.FirestoreClient.Collection("users").Doc(req.Email).Update(r.Context(), []firestore.Update{
		{Path: "password", Value: string(hashedPassword)},
	})
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "Failed to update password",
		})
		return
	}

	respondJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		Message: "Password reset successful! Please login with your new password.",
	})
}
