package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                    string
	ResendAPIKey            string
	FirebaseProjectID       string
	FirebaseCredentialsPath string
	FirebaseDatabaseURL     string
	GoogleProjectID         string
	BigQueryDataset         string
	GeminiAPIKey            string
	JWTSecret               string
}

var AppConfig *Config

func Load() error {
	_ = godotenv.Load() // Ignore error if .env doesn't exist

	AppConfig = &Config{
		Port:                    getEnv("PORT", "8080"),
		ResendAPIKey:            getEnv("RESEND_API_KEY", ""),
		FirebaseProjectID:       getEnv("FIREBASE_PROJECT_ID", ""),
		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", "./firebase-credentials.json"),
		FirebaseDatabaseURL:     getEnv("FIREBASE_DATABASE_URL", ""),
		GoogleProjectID:         getEnv("GOOGLE_PROJECT_ID", ""),
		BigQueryDataset:         getEnv("BIGQUERY_DATASET", "cognify_analytics"),
		GeminiAPIKey:            getEnv("GEMINI_API_KEY", ""),
		JWTSecret:               getEnv("JWT_SECRET", "default-secret-change-me"),
	}

	return nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
