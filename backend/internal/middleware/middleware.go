package middleware

import (
	"context"
	"net/http"
	"strings"

	"cache-crew/cognify/internal/services"
)

type contextKey string

const UserContextKey contextKey = "user"

// AuthMiddleware validates JWT tokens and adds user info to context
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte(`{"error": "Authorization header required"}`))
			return
		}

		// Extract token from "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte(`{"error": "Invalid authorization header format"}`))
			return
		}

		token := parts[1]
		claims, err := services.ValidateJWT(token)
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte(`{"error": "Invalid or expired token"}`))
			return
		}

		// Add claims and userID to context
		ctx := context.WithValue(r.Context(), UserContextKey, claims)
		ctx = context.WithValue(ctx, "userID", claims.Email) // Add userID for notifications
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// OptionalAuthMiddleware tries to validate JWT but doesn't require it
func OptionalAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				token := parts[1]
				claims, err := services.ValidateJWT(token)
				if err == nil {
					ctx := context.WithValue(r.Context(), UserContextKey, claims)
					r = r.WithContext(ctx)
				}
			}
		}
		next.ServeHTTP(w, r)
	})
}

// InstructorMiddleware ensures the user has instructor role
func InstructorMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := r.Context().Value(UserContextKey).(*services.JWTClaims)
		if !ok || claims.Role != "instructor" {
			http.Error(w, "Instructor access required", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// LoggingMiddleware logs all requests
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Simple logging - in production use a proper logger
		println("[", r.Method, "]", r.URL.Path)
		next.ServeHTTP(w, r)
	})
}
