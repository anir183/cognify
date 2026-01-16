package api

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"cache-crew/cognify/internal/models"

	"cloud.google.com/go/firestore"
	"github.com/go-chi/chi/v5"
	"google.golang.org/api/iterator"
)

// GetNotificationsHandler fetches all notifications for the current user
func GetNotificationsHandler(client *firestore.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userIDVal := r.Context().Value("userID")
		if userIDVal == nil {
			http.Error(w, `{"error": "Unauthorized"}`, http.StatusUnauthorized)
			return
		}
		userID, ok := userIDVal.(string)
		if !ok || userID == "" {
			http.Error(w, `{"error": "Unauthorized"}`, http.StatusUnauthorized)
			return
		}

		iter := client.Collection("notifications").
			Where("userId", "==", userID).
			Documents(r.Context())

		var notifications []models.Notification
		for {
			doc, err := iter.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				log.Printf("Error fetching notifications: %v", err)
				http.Error(w, "Failed to fetch notifications", http.StatusInternalServerError)
				return
			}

			var notif models.Notification
			if err := doc.DataTo(&notif); err != nil {
				log.Printf("Error parsing notification: %v", err)
				continue
			}
			notifications = append(notifications, notif)
		}

		w.Header().Set("Content-Type", "application/json")
		if notifications == nil {
			notifications = []models.Notification{}
		}
		json.NewEncoder(w).Encode(notifications)
	}
}

// MarkNotificationReadHandler marks a specific notification as read
func MarkNotificationReadHandler(client *firestore.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		notifID := chi.URLParam(r, "id")
		if notifID == "" {
			http.Error(w, "Notification ID required", http.StatusBadRequest)
			return
		}

		_, err := client.Collection("notifications").Doc(notifID).Update(r.Context(), []firestore.Update{
			{Path: "isRead", Value: true},
		})

		if err != nil {
			log.Printf("Error marking notification read: %v", err)
			http.Error(w, "Failed to update notification", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"message": "Notification marked as read"})
	}
}

// SeedNotificationsHandler creates initial notifications for a user (for testing)
func SeedNotificationsHandler(client *firestore.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Accepts userID in body to allow seeding for specific users easily
		var req struct {
			UserID string `json:"userId"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request", http.StatusBadRequest)
			return
		}

		// If no userID provided, try to use authenticated user if available, else require it
		if req.UserID == "" {
			if val := r.Context().Value("userID"); val != nil {
				req.UserID = val.(string)
			}
		}
		if req.UserID == "" {
			http.Error(w, "UserID required", http.StatusBadRequest)
			return
		}

		notifications := []models.Notification{
			{
				ID:        "notif_1_" + req.UserID,
				UserID:    req.UserID,
				Title:     "Battle Challenge!",
				Body:      "Cyber Ninja challenges you to a duel.",
				Type:      "challenge",
				IsRead:    false,
				CreatedAt: time.Now().Add(-2 * time.Minute),
			},
			{
				ID:        "notif_2_" + req.UserID,
				UserID:    req.UserID,
				Title:     "Level Up!",
				Body:      "You reached Level 5. Keep it up!",
				Type:      "level_up",
				IsRead:    false,
				CreatedAt: time.Now().Add(-2 * time.Hour),
			},
			{
				ID:        "notif_3_" + req.UserID,
				UserID:    req.UserID,
				Title:     "New Course Available",
				Body:      "Mastering Flutter Animations is now live.",
				Type:      "course",
				IsRead:    false,
				CreatedAt: time.Now().Add(-24 * time.Hour),
			},
			{
				ID:        "notif_4_" + req.UserID,
				UserID:    req.UserID,
				Title:     "Streak Saver Used",
				Body:      "You missed a day, but your streak is safe.",
				Type:      "streak",
				IsRead:    true,
				CreatedAt: time.Now().Add(-48 * time.Hour),
			},
		}

		batch := client.Batch()
		for _, n := range notifications {
			docRef := client.Collection("notifications").Doc(n.ID)
			batch.Set(docRef, n)
		}

		if _, err := batch.Commit(r.Context()); err != nil {
			log.Printf("Error seeding notifications: %v", err)
			http.Error(w, "Failed to seed notifications", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"message": "Seeded 4 notifications",
			"userId":  req.UserID,
		})
	}
}
