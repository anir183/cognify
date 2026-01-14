package api

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"

	"google.golang.org/api/iterator"
)

// Mock courses for when Firestore is not available
var mockCourses = []models.Course{
	{
		ID:          "1",
		Title:       "Flutter Mastery",
		Subtitle:    "Build beautiful apps",
		Description: "Learn to build stunning cross-platform apps with Flutter",
		Emoji:       "🚀",
		ColorHex:    "0xFF00F5FF",
		Tags:        []string{"mobile", "flutter", "dart"},
	},
	{
		ID:          "2",
		Title:       "AI Basics",
		Subtitle:    "Machine Learning 101",
		Description: "Introduction to artificial intelligence and machine learning",
		Emoji:       "🤖",
		ColorHex:    "0xFFBF00FF",
		Tags:        []string{"ai", "ml", "python"},
	},
	{
		ID:          "3",
		Title:       "Web Dev",
		Subtitle:    "HTML, CSS, JS",
		Description: "Master modern web development technologies",
		Emoji:       "🌐",
		ColorHex:    "0xFFFF00A0",
		Tags:        []string{"web", "javascript", "frontend"},
	},
	{
		ID:          "4",
		Title:       "Data Science",
		Subtitle:    "Python & Stats",
		Description: "Analyze data and build insights with Python",
		Emoji:       "📊",
		ColorHex:    "0xFF00FF7F",
		Tags:        []string{"data", "python", "analytics"},
	},
	{
		ID:          "5",
		Title:       "Go Programming",
		Subtitle:    "Backend Development",
		Description: "Build scalable backend services with Go",
		Emoji:       "🔷",
		ColorHex:    "0xFF00ADD8",
		Tags:        []string{"backend", "go", "api"},
	},
}

// GetCoursesHandler returns all available courses
func GetCoursesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	courses, err := getCourses(r.Context())
	if err != nil {
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"error": "Failed to fetch courses",
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"courses": courses,
	})
}

// GetCourseHandler returns a specific course by ID
func GetCourseHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	courseID := r.URL.Query().Get("id")
	if courseID == "" {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Course ID is required",
		})
		return
	}

	course, err := getCourseByID(r.Context(), courseID)
	if err != nil {
		respondJSON(w, http.StatusNotFound, map[string]string{
			"error": "Course not found",
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"course":  course,
	})
}

// EnrollCourseHandler enrolls a user in a course
func EnrollCourseHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		UserID   string `json:"userId"`
		CourseID string `json:"courseId"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
		return
	}

	enrollment := &models.Enrollment{
		ID:        req.UserID + "_" + req.CourseID,
		UserID:    req.UserID,
		CourseID:  req.CourseID,
		Progress:  0,
		Completed: false,
		StartedAt: time.Now(),
	}

	if db.FirestoreClient != nil {
		_, err := db.FirestoreClient.Collection("enrollments").Doc(enrollment.ID).Set(r.Context(), enrollment)
		if err != nil {
			respondJSON(w, http.StatusInternalServerError, map[string]string{
				"error": "Failed to enroll in course",
			})
			return
		}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success":    true,
		"message":    "Enrolled successfully",
		"enrollment": enrollment,
	})
}

func getCourses(ctx context.Context) ([]models.Course, error) {
	if db.FirestoreClient == nil {
		return mockCourses, nil
	}

	iter := db.FirestoreClient.Collection("courses").Documents(ctx)
	var courses []models.Course

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return mockCourses, nil // Fallback to mock on error
		}

		var course models.Course
		if err := doc.DataTo(&course); err != nil {
			continue
		}
		courses = append(courses, course)
	}

	if len(courses) == 0 {
		return mockCourses, nil
	}

	return courses, nil
}

func getCourseByID(ctx context.Context, id string) (*models.Course, error) {
	if db.FirestoreClient == nil {
		for _, c := range mockCourses {
			if c.ID == id {
				return &c, nil
			}
		}
		return nil, nil
	}

	doc, err := db.FirestoreClient.Collection("courses").Doc(id).Get(ctx)
	if err != nil {
		// Fallback to mock
		for _, c := range mockCourses {
			if c.ID == id {
				return &c, nil
			}
		}
		return nil, err
	}

	var course models.Course
	if err := doc.DataTo(&course); err != nil {
		return nil, err
	}

	return &course, nil
}
