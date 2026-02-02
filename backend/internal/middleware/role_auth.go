package middleware

import (
	"context"
	"net/http"
)

// RoleAuthMiddleware checks if user has required role
func RoleAuthMiddleware(requiredRole string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Get wallet from context (set by WalletAuthMiddleware)
			wallet := r.Context().Value("wallet")
			if wallet == nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			// Get user role from context
			role := r.Context().Value("role")
			if role == nil {
				http.Error(w, "Role not found", http.StatusForbidden)
				return
			}

			// Check if role matches
			if role.(string) != requiredRole {
				http.Error(w, "Insufficient permissions", http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// InstructorOnlyMiddleware restricts access to authorized instructors
func InstructorOnlyMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Get role from context
		role := r.Context().Value("role")
		if role == nil || role.(string) != "instructor" {
			http.Error(w, "Instructor access required", http.StatusForbidden)
			return
		}

		// Check if instructor is authorized
		isAuthorized := r.Context().Value("is_authorized")
		if isAuthorized == nil || !isAuthorized.(bool) {
			http.Error(w, "Instructor not authorized", http.StatusForbidden)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// PublicEndpoint marks an endpoint as public (no auth required)
func PublicEndpoint(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Add public context flag
		ctx := context.WithValue(r.Context(), "public", true)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
