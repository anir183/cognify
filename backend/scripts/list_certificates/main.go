package main

import (
	"context"
	"fmt"
	"log"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

func main() {
	ctx := context.Background()

	// Initialize Firestore
	opt := option.WithCredentialsFile("../serviceAccountKey.json")
	client, err := firestore.NewClient(ctx, "cognify-dev-b9e5a", opt)
	if err != nil {
		log.Fatalf("Failed to create Firestore client: %v", err)
	}
	defer client.Close()

	// Fetch all certificates
	iter := client.Collection("certificates").Limit(5).Documents(ctx)
	defer iter.Stop()

	fmt.Println("📋 Existing Certificates in Firestore:\n")
	count := 0
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Printf("Error fetching document: %v", err)
			continue
		}

		data := doc.Data()
		count++
		fmt.Printf("%d. Hash: %s\n", count, doc.Ref.ID)
		fmt.Printf("   Student: %v\n", data["student_name"])
		fmt.Printf("   Course: %v\n", data["course_name"])
		fmt.Printf("   Trust Score: %v\n", data["trust_score"])
		fmt.Printf("   Verifications: %v\n\n", data["verification_count"])
	}

	if count == 0 {
		fmt.Println("No certificates found in database.")
	} else {
		fmt.Printf("\n✅ Found %d certificates\n", count)
	}
}
