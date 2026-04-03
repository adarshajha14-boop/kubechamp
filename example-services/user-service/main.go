package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Metrics
var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)
	httpDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name: "http_request_duration_seconds",
			Help: "HTTP request duration in seconds",
		},
		[]string{"method", "endpoint"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpDuration)
}

type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
	Version   string `json:"version"`
}

type UserResponse struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	defer func() {
		duration := time.Since(start).Seconds()
		httpDuration.WithLabelValues(r.Method, "/health").Observe(duration)
	}()

	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Version:   os.Getenv("APP_VERSION"),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	httpRequestsTotal.WithLabelValues(r.Method, "/health", "200").Inc()
}

func usersHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	defer func() {
		duration := time.Since(start).Seconds()
		httpDuration.WithLabelValues(r.Method, "/api/users").Observe(duration)
	}()

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		httpRequestsTotal.WithLabelValues(r.Method, "/api/users", "405").Inc()
		return
	}

	users := []UserResponse{
		{ID: "1", Name: "Alice", Email: "alice@example.com"},
		{ID: "2", Name: "Bob", Email: "bob@example.com"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
	httpRequestsTotal.WithLabelValues(r.Method, "/api/users", "200").Inc()
}

func main() {
	// Setup logging
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Environment variables
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Routes
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/api/users", usersHandler)
	http.Handle("/metrics", promhttp.Handler())

	// Server
	server := http.Server{
		Addr:              ":" + port,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("Server starting on port %s", port)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server error: %v", err)
	}
}
