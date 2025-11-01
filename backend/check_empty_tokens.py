#!/usr/bin/env python3
"""
Script to check for empty or problematic tokens
"""
import os
import sys
from dotenv import load_dotenv
from supabase import create_client

def main():
    # Load environment variables
    load_dotenv()
    
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
        sys.exit(1)
    
    # Create Supabase client
    supabase = create_client(supabase_url, supabase_key)
    
    try:
        # Get all tokens
        print("Checking for problematic tokens...")
        response = supabase.table("encrypted_tokens").select("*").execute()
        tokens = response.data
        
        print(f"Total tokens: {len(tokens)}")
        
        empty_tokens = []
        short_tokens = []
        
        for token in tokens:
            encrypted_value = token['encrypted_token']
            
            # Check for empty or very short tokens
            if not encrypted_value or encrypted_value.strip() == "":
                empty_tokens.append(token)
            elif len(encrypted_value) < 50:  # Encrypted tokens should be much longer
                short_tokens.append(token)
        
        print(f"Empty tokens: {len(empty_tokens)}")
        for token in empty_tokens:
            print(f"  - {token['token_type']} for user {token['user_id'][:8]}...")
        
        print(f"Suspiciously short tokens: {len(short_tokens)}")
        for token in short_tokens:
            print(f"  - {token['token_type']} for user {token['user_id'][:8]}... (length: {len(token['encrypted_token'])})")
        
        # Check for tokens that might be the literal string "EMPTY"
        response = supabase.table("encrypted_tokens").select("*").eq("encrypted_token", "EMPTY").execute()
        literal_empty = response.data
        print(f"Tokens with literal 'EMPTY' value: {len(literal_empty)}")
        
        # Check for null tokens
        response = supabase.table("encrypted_tokens").select("*").is_("encrypted_token", "null").execute()
        null_tokens = response.data
        print(f"Null tokens: {len(null_tokens)}")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()