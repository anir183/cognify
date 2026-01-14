package api

import (
	"encoding/json"
	"net/http"
	"time"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"
	"cache-crew/cognify/internal/services"
)

// GenerateCertificateRequest represents a certificate generation request
type GenerateCertificateRequest struct {
	UserID       string `json:"userId"`
	UserName     string `json:"userName"`
	CourseID     string `json:"courseId"`
	CourseName   string `json:"courseName"`
	CompletionData string `json:"completionData,omitempty"`
}

// GenerateCertificateHandler handles certificate generation for instructors
func GenerateCertificateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req GenerateCertificateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
		return
	}

	if req.UserID == "" || req.UserName == "" || req.CourseID == "" || req.CourseName == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "UserID, UserName, CourseID, and CourseName are required",
		})
		return
	}

	// Generate certificate content using Gemini
	content, err := services.GenerateCertificateContent(
		r.Context(),
		req.UserName,
		req.CourseName,
		req.CompletionData,
	)
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to generate certificate content",
		})
		return
	}

	issuedAt := time.Now()

	// Generate PDF
	pdfBytes, err := services.GenerateCertificatePDF(
		req.UserName,
		req.CourseName,
		content.Achievement,
		content.Skills,
		content.CongratMessage,
		issuedAt,
	)
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to generate certificate PDF",
		})
		return
	}

	// Create certificate record
	certificate := &models.Certificate{
		ID:          generateID(),
		UserID:      req.UserID,
		UserName:    req.UserName,
		CourseID:    req.CourseID,
		CourseTitle: req.CourseName,
		IssuedAt:    issuedAt,
		Skills:      content.Skills,
		Message:     content.CongratMessage,
	}

	// Save to Firestore if available
	if db.FirestoreClient != nil {
		_, _ = db.FirestoreClient.Collection("certificates").Doc(certificate.ID).Set(r.Context(), certificate)
	}

	// Return PDF as response
	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", "attachment; filename=certificate_"+req.UserID+"_"+req.CourseID+".pdf")
	w.Write(pdfBytes)
}

// GetCertificateDataHandler returns certificate data without generating PDF
func GetCertificateDataHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req GenerateCertificateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
		return
	}

	// Generate certificate content using Gemini
	content, err := services.GenerateCertificateContent(
		r.Context(),
		req.UserName,
		req.CourseName,
		req.CompletionData,
	)
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to generate certificate content",
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success":     true,
		"content":     content,
		"studentName": req.UserName,
		"courseName":  req.CourseName,
	})
}

// InstructorDashboardHandler returns instructor dashboard data
func InstructorDashboardHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	instructorID := r.URL.Query().Get("instructorId")
	if instructorID == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Instructor ID is required",
		})
		return
	}

	// Mock data for dashboard
	dashboardData := map[string]interface{}{
		"totalStudents":   156,
		"activeCourses":   5,
		"totalEnrollments": 423,
		"completionRate":   0.72,
		"recentActivity": []map[string]interface{}{
			{"type": "enrollment", "student": "Alex Chen", "course": "Flutter Mastery", "time": time.Now().Add(-2 * time.Hour)},
			{"type": "completion", "student": "Sarah Kim", "course": "AI Basics", "time": time.Now().Add(-5 * time.Hour)},
		},
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    dashboardData,
	})
}
