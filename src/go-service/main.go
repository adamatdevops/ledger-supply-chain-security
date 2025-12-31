// Package main implements a notification service for the Ledger platform.
// This service handles async notifications (email, webhook, SMS).
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

// Config holds service configuration
type Config struct {
	Port    string
	Version string
}

// HealthResponse represents health check response
type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
}

// VersionResponse represents version endpoint response
type VersionResponse struct {
	Version  string `json:"version"`
	Service  string `json:"service"`
	Language string `json:"language"`
}

// NotificationRequest represents incoming notification request
type NotificationRequest struct {
	Type      string                 `json:"type"`      // email, webhook, sms
	Recipient string                 `json:"recipient"` // email address, URL, or phone
	Subject   string                 `json:"subject"`
	Body      string                 `json:"body"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// NotificationResponse represents notification API response
type NotificationResponse struct {
	Status         string `json:"status"`
	NotificationID string `json:"notification_id"`
	Timestamp      string `json:"timestamp"`
}

// ErrorResponse represents error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Details string `json:"details,omitempty"`
}

var config Config

func init() {
	config = Config{
		Port:    getEnv("PORT", "8082"),
		Version: getEnv("VERSION", "1.0.0"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		jsonResponse(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}

	jsonResponse(w, http.StatusOK, HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	})
}

func versionHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		jsonResponse(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}

	jsonResponse(w, http.StatusOK, VersionResponse{
		Version:  config.Version,
		Service:  "notification-service",
		Language: "go",
	})
}

func notifyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		jsonResponse(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}

	var req NotificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonResponse(w, http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid JSON",
			Details: err.Error(),
		})
		return
	}

	// Validate required fields
	if req.Type == "" || req.Recipient == "" || req.Body == "" {
		jsonResponse(w, http.StatusBadRequest, ErrorResponse{
			Error: "Missing required fields: type, recipient, body",
		})
		return
	}

	// Validate notification type
	validTypes := map[string]bool{"email": true, "webhook": true, "sms": true}
	if !validTypes[req.Type] {
		jsonResponse(w, http.StatusBadRequest, ErrorResponse{
			Error: "Invalid notification type. Must be: email, webhook, or sms",
		})
		return
	}

	// Generate notification ID (in production, would queue for async processing)
	notificationID := fmt.Sprintf("notif-%d", time.Now().UnixNano())

	log.Printf("Notification queued: id=%s type=%s recipient=%s", notificationID, req.Type, req.Recipient)

	jsonResponse(w, http.StatusAccepted, NotificationResponse{
		Status:         "queued",
		NotificationID: notificationID,
		Timestamp:      time.Now().UTC().Format(time.RFC3339),
	})
}

func main() {
	mux := http.NewServeMux()

	// Register routes
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/version", versionHandler)
	mux.HandleFunc("/notify", notifyHandler)

	addr := fmt.Sprintf(":%s", config.Port)
	log.Printf("Notification service v%s starting on %s", config.Version, addr)

	server := &http.Server{
		Addr:         addr,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
