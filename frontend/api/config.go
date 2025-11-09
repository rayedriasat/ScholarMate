package handler

import (
	"encoding/json"
	"net/http"
	"os"
)

type config struct {
	GoogleClientID     string `json:"GOOGLE_CLIENT_ID"`
	GoogleClientSecret string `json:"GOOGLE_CLIENT_SECRET"`
	GoogleRedirectURI  string `json:"GOOGLE_REDIRECT_URI"`
	APIBaseURL         string `json:"API_BASE_URL"`
	SupabaseURL        string `json:"SUPABASE_URL"`
	SupabaseAnonKey    string `json:"SUPABASE_ANON_KEY"`
}

func Handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*") // tighten in production

	json.NewEncoder(w).Encode(config{
		GoogleClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
		GoogleClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
		GoogleRedirectURI:  os.Getenv("GOOGLE_REDIRECT_URI"),
		APIBaseURL:         os.Getenv("API_BASE_URL"),
		SupabaseURL:        os.Getenv("SUPABASE_URL"),
		SupabaseAnonKey:    os.Getenv("SUPABASE_ANON_KEY"),
	})
}
