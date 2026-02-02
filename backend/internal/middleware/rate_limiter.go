package middleware

import (
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// RateLimiter stores rate limiters per IP address
type RateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rate     rate.Limit
	burst    int
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(requestsPerSecond int, burst int) *RateLimiter {
	return &RateLimiter{
		limiters: make(map[string]*rate.Limiter),
		rate:     rate.Limit(requestsPerSecond),
		burst:    burst,
	}
}

// GetLimiter returns the rate limiter for an IP address
func (rl *RateLimiter) GetLimiter(ip string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	limiter, exists := rl.limiters[ip]
	if !exists {
		limiter = rate.NewLimiter(rl.rate, rl.burst)
		rl.limiters[ip] = limiter
	}

	return limiter
}

// CleanupOldLimiters removes inactive limiters (run periodically)
func (rl *RateLimiter) CleanupOldLimiters() {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	for ip, limiter := range rl.limiters {
		if limiter.Tokens() == float64(rl.burst) {
			delete(rl.limiters, ip)
		}
	}
}

// RateLimitMiddleware creates a rate limiting middleware
func RateLimitMiddleware(requestsPerSecond int, burst int) func(http.Handler) http.Handler {
	limiter := NewRateLimiter(requestsPerSecond, burst)

	// Start cleanup goroutine
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()

		for range ticker.C {
			limiter.CleanupOldLimiters()
		}
	}()

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Get IP address
			ip := r.RemoteAddr
			if forwarded := r.Header.Get("X-Forwarded-For"); forwarded != "" {
				ip = forwarded
			}

			// Get limiter for this IP
			ipLimiter := limiter.GetLimiter(ip)

			// Check if request is allowed
			if !ipLimiter.Allow() {
				http.Error(w, "Rate limit exceeded. Please try again later.", http.StatusTooManyRequests)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// PublicRateLimitMiddleware applies stricter rate limiting for public endpoints
func PublicRateLimitMiddleware() func(http.Handler) http.Handler {
	// 100 requests per minute for public endpoints
	return RateLimitMiddleware(100, 100)
}

// AuthenticatedRateLimitMiddleware applies lenient rate limiting for authenticated users
func AuthenticatedRateLimitMiddleware() func(http.Handler) http.Handler {
	// 1000 requests per minute for authenticated users
	return RateLimitMiddleware(1000, 1000)
}
