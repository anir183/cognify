package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"

	"cache-crew/cognify/internal/config"
)

var geminiClient *genai.Client
var geminiModel *genai.GenerativeModel

// InitGemini initializes the Gemini AI client
func InitGemini(ctx context.Context) error {
	apiKey := config.AppConfig.GeminiAPIKey
	if apiKey == "" {
		log.Println("Gemini: No API key configured, running in mock mode")
		return nil
	}

	var err error
	geminiClient, err = genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		log.Printf("Warning: Could not initialize Gemini: %v", err)
		return nil
	}

	geminiModel = geminiClient.GenerativeModel("gemini-2.5-flash")
	log.Println("Gemini AI initialized successfully")
	return nil
}

// CloseGemini closes the Gemini client
func CloseGemini() {
	if geminiClient != nil {
		geminiClient.Close()
	}
}

// GetGeminiModel returns the initialized Gemini model (or nil if not initialized)
func GetGeminiModel() *genai.GenerativeModel {
	return geminiModel
}

// ChatWithAI sends a message to Gemini and returns the response
func ChatWithAI(ctx context.Context, message string, context string) (string, error) {
	if geminiModel == nil {
		// Mock mode
		log.Println("DEBUG: Gemini in mock mode")
		return fmt.Sprintf("[Mock AI Response] You asked: %s", message), nil
	}

	prompt := message
	if context != "" {
		prompt = fmt.Sprintf("Context: %s\n\nUser message: %s", context, message)
	}

	// Add system instruction for concise responses
	systemInstruction := "You are 'The Oracle', an AI learning assistant for Cognify, a gamified education platform. " +
		"Keep your responses concise, helpful, and under 150 words. " +
		"Be friendly and encouraging. " +
		"IMPORTANT: Do NOT use any markdown formatting like **, ##, or bullet points with *. " +
		"Use plain text with simple dashes (-) for lists if needed. " +
		"Write in a conversational, easy-to-read style."
	prompt = fmt.Sprintf("%s\n\nUser: %s", systemInstruction, prompt)

	log.Printf("DEBUG: Sending prompt to Gemini: %s\n", prompt[:min(200, len(prompt))])

	resp, err := geminiModel.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		log.Printf("DEBUG: Gemini GenerateContent error: %v\n", err)
		return "", err
	}

	log.Printf("DEBUG: Gemini response candidates count: %d\n", len(resp.Candidates))
	var result strings.Builder
	for i, candidate := range resp.Candidates {
		log.Printf("DEBUG: Processing candidate %d\n", i)
		if candidate.Content != nil {
			log.Printf("DEBUG: Candidate %d has %d parts\n", i, len(candidate.Content.Parts))
			for j, part := range candidate.Content.Parts {
				partStr := fmt.Sprintf("%v", part)
				log.Printf("DEBUG: Part %d: %s\n", j, partStr[:min(100, len(partStr))])
				result.WriteString(partStr)
			}
		} else {
			log.Printf("DEBUG: Candidate %d has nil Content\n", i)
		}
	}

	finalResult := result.String()
	log.Printf("DEBUG: Final result length: %d\n", len(finalResult))
	return finalResult, nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ChatWithImage analyzes an image with optional text prompt using Gemini Vision
func ChatWithImage(ctx context.Context, message string, imageData []byte, mimeType string) (string, error) {
	if geminiClient == nil {
		log.Println("DEBUG: Gemini Vision in mock mode")
		return "[Mock Vision Response] I can see you've uploaded an image. In a live session, I would analyze it for you!", nil
	}

	// Use the model specified by user
	visionModel := geminiClient.GenerativeModel("gemini-2.5-flash-lite")

	// System instruction for image analysis
	systemInstruction := "You are 'The Oracle', an AI learning assistant with vision capabilities. " +
		"Analyze the image provided and respond helpfully. " +
		"If the user asks a question about the image, answer it. " +
		"If no specific question is asked, describe the key elements and offer insights. " +
		"Keep responses concise (under 200 words). " +
		"Do NOT use markdown formatting (no **, ##, or *). Use plain text."

	// Build prompt parts
	var prompt string
	if message != "" {
		prompt = fmt.Sprintf("%s\n\nUser's question about the image: %s", systemInstruction, message)
	} else {
		prompt = fmt.Sprintf("%s\n\nPlease analyze this image and describe what you see.", systemInstruction)
	}

	// Create image part - genai.ImageData expects format like "png", "jpeg" not full MIME type
	// Extract format from MIME type (e.g., "image/png" -> "png")
	format := mimeType
	if strings.HasPrefix(mimeType, "image/") {
		format = strings.TrimPrefix(mimeType, "image/")
	}
	imagePart := genai.ImageData(format, imageData)
	textPart := genai.Text(prompt)

	log.Printf("DEBUG: Sending image to Gemini Vision (size: %d bytes, format: %s)\n", len(imageData), format)

	resp, err := visionModel.GenerateContent(ctx, textPart, imagePart)
	if err != nil {
		log.Printf("DEBUG: Gemini Vision error: %v\n", err)
		// Return error as message so it appears in chat
		return fmt.Sprintf("I encountered an issue analyzing this image: %v. Please make sure the AI model is valid.", err), nil
	}

	var result strings.Builder
	for _, candidate := range resp.Candidates {
		if candidate.Content != nil {
			for _, part := range candidate.Content.Parts {
				result.WriteString(fmt.Sprintf("%v", part))
			}
		}
	}

	finalResult := result.String()
	log.Printf("DEBUG: Vision result length: %d\n", len(finalResult))

	if finalResult == "" {
		return "I analyzed the image but couldn't generate a description. Please try asking a specific question about it!", nil
	}

	return finalResult, nil
}

// SupportChatWithAI handles support-related conversations with a specialized persona
func SupportChatWithAI(ctx context.Context, message string, conversationContext string) (string, error) {
	if geminiModel == nil {
		// Mock mode
		log.Println("DEBUG: Support chat in mock mode")
		return "[Mock Support] Thanks for reaching out! I'm here to help with billing, account, or app issues. How can I assist you today?", nil
	}

	prompt := message
	if conversationContext != "" {
		prompt = fmt.Sprintf("Previous conversation:\n%s\n\nUser: %s", conversationContext, message)
	}

	// Support-focused system instruction
	systemInstruction := "You are 'Sarah', a friendly and professional customer support agent for Cognify, an educational app. " +
		"Your role is to help users with:\n" +
		"- Billing and subscription issues\n" +
		"- Account problems (login, password, profile)\n" +
		"- App bugs or technical issues\n" +
		"- General questions about Cognify features\n\n" +
		"Guidelines:\n" +
		"- Be empathetic and professional\n" +
		"- Keep responses concise (under 100 words)\n" +
		"- If you cannot solve an issue, offer to escalate to a human agent\n" +
		"- Do NOT use markdown formatting (no **, ##, or *)\n" +
		"- Use plain text with dashes for lists if needed"
	prompt = fmt.Sprintf("%s\n\nUser: %s", systemInstruction, prompt)

	resp, err := geminiModel.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		log.Printf("DEBUG: Support chat Gemini error: %v\n", err)
		return "", err
	}

	var result strings.Builder
	for _, candidate := range resp.Candidates {
		if candidate.Content != nil {
			for _, part := range candidate.Content.Parts {
				result.WriteString(fmt.Sprintf("%v", part))
			}
		}
	}

	return result.String(), nil
}

// SummarizeData uses Gemini to summarize analytics data
func SummarizeData(ctx context.Context, dataType string, data string) (string, error) {
	if geminiModel == nil {
		return fmt.Sprintf("[Mock Summary] Analyzed %s data with key insights.", dataType), nil
	}

	prompt := fmt.Sprintf(`You are an educational analytics assistant for Cognify, a gamified learning platform.
Analyze the following %s data and provide a concise, actionable summary for instructors.
Focus on:
- Key trends and patterns
- Areas of concern
- Recommendations for improvement
- Student engagement insights

Data:
%s

Please provide a well-structured summary.`, dataType, data)

	resp, err := geminiModel.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return "", err
	}

	var result strings.Builder
	for _, candidate := range resp.Candidates {
		if candidate.Content != nil {
			for _, part := range candidate.Content.Parts {
				result.WriteString(fmt.Sprintf("%v", part))
			}
		}
	}

	return result.String(), nil
}

// GenerateCertificateContent generates personalized certificate text using Gemini
func GenerateCertificateContent(ctx context.Context, studentName, courseName string, completionData string) (*CertificateContent, error) {
	if geminiModel == nil {
		return &CertificateContent{
			CongratMessage: fmt.Sprintf("Congratulations %s on completing %s!", studentName, courseName),
			Skills:         []string{"Critical Thinking", "Problem Solving", "Domain Knowledge"},
			Achievement:    "Outstanding Learner",
		}, nil
	}

	prompt := fmt.Sprintf(`Generate certificate content for a student who completed a course on the Cognify platform.

Student Name: %s
Course Name: %s
Completion Data: %s

Generate:
1. A personalized congratulatory message (2-3 sentences, professional yet warm)
2. A list of 3-5 skills acquired from this course
3. An achievement title (e.g., "Distinguished Scholar", "Rising Star")

Respond in this exact JSON format:
{
  "congratMessage": "...",
  "skills": ["skill1", "skill2", "skill3"],
  "achievement": "..."
}`, studentName, courseName, completionData)

	resp, err := geminiModel.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, err
	}

	// Parse response (simplified - in production, properly parse JSON)
	var responseText strings.Builder
	for _, candidate := range resp.Candidates {
		if candidate.Content != nil {
			for _, part := range candidate.Content.Parts {
				responseText.WriteString(fmt.Sprintf("%v", part))
			}
		}
	}

	// For now, return a default structure (proper JSON parsing would be added)
	return &CertificateContent{
		CongratMessage: fmt.Sprintf("Congratulations %s on completing %s! Your dedication and hard work have paid off.", studentName, courseName),
		Skills:         []string{"Critical Thinking", "Problem Solving", "Domain Expertise"},
		Achievement:    "Distinguished Scholar",
	}, nil
}

type CertificateContent struct {
	CongratMessage string   `json:"congratMessage"`
	Skills         []string `json:"skills"`
	Achievement    string   `json:"achievement"`
}

// GenerateAnalyticsInsights generates insights for instructor analytics
func GenerateAnalyticsInsights(ctx context.Context, dataSummary string) (*struct {
	Roadblocks      []string `json:"roadblocks"`
	Recommendations []string `json:"recommendations"`
}, error) {
	// Define the return structure type
	type InsightsResponse struct {
		Roadblocks      []string `json:"roadblocks"`
		Recommendations []string `json:"recommendations"`
	}

	if geminiModel == nil {
		return &struct {
			Roadblocks      []string `json:"roadblocks"`
			Recommendations []string `json:"recommendations"`
		}{
			Roadblocks: []string{
				"45% of students struggle with State Management",
				"Quiz 2 has a 35% failure rate",
				"Module 5 completion time is high",
			},
			Recommendations: []string{
				"Add video tutorial for Riverpod",
				"Create practice exercises before Quiz 2",
				"Split Module 5 into smaller sections",
			},
		}, nil
	}

	prompt := fmt.Sprintf(`Analyze the following student progress data and provide insights for the instructor.
Data Summary:
%s

Generate:
1. 3 Common Roadblocks observed (concise bullet points)
2. 3 Specific Recommendations to improve course delivery

Respond in this exact JSON format:
{
  "roadblocks": ["roadblock1", "roadblock2", "roadblock3"],
  "recommendations": ["rec1", "rec2", "rec3"]
}
Do not include markdown formatting like '''json. Just the raw JSON.`, dataSummary)

	resp, err := geminiModel.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, err
	}

	var responseText strings.Builder
	for _, candidate := range resp.Candidates {
		if candidate.Content != nil {
			for _, part := range candidate.Content.Parts {
				responseText.WriteString(fmt.Sprintf("%v", part))
			}
		}
	}

	rawJSON := responseText.String()
	// Clean up potential markdown code blocks
	rawJSON = strings.TrimPrefix(rawJSON, "```json")
	rawJSON = strings.TrimPrefix(rawJSON, "```")
	rawJSON = strings.TrimSuffix(rawJSON, "```")
	rawJSON = strings.TrimSpace(rawJSON)

	var insights InsightsResponse
	if err := json.Unmarshal([]byte(rawJSON), &insights); err != nil {
		log.Printf("Error parsing Gemini JSON: %v, Raw: %s", err, rawJSON)
		// Fallback to default if parsing fails
		return &struct {
			Roadblocks      []string `json:"roadblocks"`
			Recommendations []string `json:"recommendations"`
		}{
			Roadblocks:      []string{"Unable to parse insights", "Check logs for details"},
			Recommendations: []string{"Try refreshing analytics"},
		}, nil
	}

	// copy to anonymous struct to match return type
	return &struct {
		Roadblocks      []string `json:"roadblocks"`
		Recommendations []string `json:"recommendations"`
	}{
		Roadblocks:      insights.Roadblocks,
		Recommendations: insights.Recommendations,
	}, nil
}
