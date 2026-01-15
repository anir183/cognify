package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"cache-crew/cognify/internal/db"
	"cache-crew/cognify/internal/models"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/iterator"
)

// RecommendationRequest contains the context for generating recommendations
type RecommendationRequest struct {
	UserID        string
	UserLevel     string                   // e.g. "Cyber Ninja"
	UserModifier  string                   // e.g. "Hard"
	WeakPoints    []string                 // e.g. ["State Management", "API"]
	RecentScores  []map[string]interface{} // e.g. [{"topic":"Dart", "score":90}]
	LearningStyle string                   // e.g. "Visual"
}

// GetCourseRecommendations generates AI recommendations
func GetCourseRecommendations(ctx context.Context, req RecommendationRequest) ([]models.AIRecommendation, error) {
	// 1. Fetch available courses
	courses, err := fetchAvailableCourses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch courses: %v", err)
	}

	// 2. Prepare data for Gemini
	coursesJSON, _ := json.Marshal(courses)
	scoresJSON, _ := json.Marshal(req.RecentScores)
	weakPointsStr := strings.Join(req.WeakPoints, ", ")

	// 3. Construct Prompt
	prompt := fmt.Sprintf(`
Analyze the following user profile and available course list to generate learning recommendations.

USER PROFILE:
- Current Level: %s
- Current Difficulty Modifier: %s
- Recent Weak Points: [%s]
- Recent Quiz Scores: %s
- Learning Style: %s

AVAILABLE COURSES/QUESTS DATABASE:
%s

TASK:
1. Identify the user's critical "Weak Points" from recent low scores.
2. Select 3 items from the "Available Courses" that directly address these weak points.
    - If the user is struggling (low scores), recommend content with a lower difficulty rating than their current modifier.
    - If the user is excelling (high scores), recommend "Challenge Quests" with higher difficulty.
3. For each recommendation, provide a BRIEF explanation (MAXIMUM 50 words) of why it was chosen.

Respond in this JSON format ONLY (no markdown):
[
  {
    "courseId": "ID_FROM_DATABASE",
    "reason": "Brief explanation (max 50 words)"
  }
]
`, req.UserLevel, req.UserModifier, weakPointsStr, string(scoresJSON), req.LearningStyle, string(coursesJSON))

	// 4. Call Gemini
	if geminiModel == nil {
		return nil, fmt.Errorf("gemini model not initialized")
	}

	log.Println("DEBUG: Sending recommendation prompt to Gemini...")
	resp, err := geminiModel.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, fmt.Errorf("gemini generation error: %v", err)
	}

	var resultText string
	for _, cand := range resp.Candidates {
		if cand.Content != nil {
			for _, part := range cand.Content.Parts {
				resultText += fmt.Sprintf("%v", part)
			}
		}
	}

	// Clean up result (remove markdown code blocks if present)
	resultText = strings.TrimPrefix(resultText, "```json")
	resultText = strings.TrimPrefix(resultText, "```")
	resultText = strings.TrimSuffix(resultText, "```")

	// 5. Parse JSON
	var recs []struct {
		CourseID string `json:"courseId"`
		Reason   string `json:"reason"`
	}
	if err := json.Unmarshal([]byte(resultText), &recs); err != nil {
		log.Printf("Failed to parse Gemini JSON: %s", resultText)
		return nil, fmt.Errorf("failed to parse AI response: %v", err)
	}

	// 6. Map to Model
	var finalRecs []models.AIRecommendation
	for _, r := range recs {
		finalRecs = append(finalRecs, models.AIRecommendation{
			UserID:   req.UserID,
			CourseID: r.CourseID,
			Reason:   r.Reason,
		})
	}

	return finalRecs, nil
}

func fetchAvailableCourses(ctx context.Context) ([]models.Course, error) {
	if db.FirestoreClient == nil {
		// Return mock data if DB not ready
		return getMockCourses(), nil
	}

	var courses []models.Course
	iter := db.FirestoreClient.Collection("courses").Documents(ctx)
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		var c models.Course
		doc.DataTo(&c)
		courses = append(courses, c)
	}

	// If DB is empty, use mock
	if len(courses) == 0 {
		return getMockCourses(), nil
	}

	return courses, nil
}

func getMockCourses() []models.Course {
	return []models.Course{
		{ID: "c1", Title: "Flutter Basics", Subtitle: "Build Your First App", Description: "Intro to Flutter", DifficultyRating: 1, Tags: []string{"Flutter", "Basics"}, Emoji: "🦋", ColorHex: "0xFF00BCD4"},
		{ID: "c2", Title: "State Management", Subtitle: "Master Riverpod", Description: "Master Providers", DifficultyRating: 3, Tags: []string{"State Management", "Provider"}, Emoji: "🧠", ColorHex: "0xFF9C27B0"},
		{ID: "c3", Title: "Advanced Animations", Subtitle: "Complex UI Magic", Description: "Complex UI", DifficultyRating: 5, Tags: []string{"Animation", "UI"}, Emoji: "✨", ColorHex: "0xFFFF5722"},
		{ID: "c4", Title: "Dart Fundamentals", Subtitle: "Core Language Skills", Description: "Learn Dart from scratch", DifficultyRating: 1, Tags: []string{"Dart", "Basics"}, Emoji: "🎯", ColorHex: "0xFF2196F3"},
		{ID: "c5", Title: "Asynchronous Dart", Subtitle: "Futures & Streams", Description: "Master async/await", DifficultyRating: 3, Tags: []string{"Dart", "Async"}, Emoji: "⚡", ColorHex: "0xFFFFEB3B"},
	}
}
