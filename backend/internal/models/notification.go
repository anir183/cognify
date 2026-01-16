package models

import "time"

type Notification struct {
	ID        string    `json:"id" firestore:"id"`
	UserID    string    `json:"userId" firestore:"userId"`
	Title     string    `json:"title" firestore:"title"`
	Body      string    `json:"body" firestore:"body"`
	Type      string    `json:"type" firestore:"type"` // "challenge", "level_up", "system", "streak"
	IsRead    bool      `json:"isRead" firestore:"isRead"`
	CreatedAt time.Time `json:"createdAt" firestore:"createdAt"`
}
