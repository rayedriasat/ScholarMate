#!/usr/bin/env python3
"""
Script to debug what's in the encrypted_tokens table
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
        print("Fetching all encrypted tokens...")
        response = supabase.table("encrypted_tokens").select("*").execute()
        tokens = response.data
        
        print(f"Found {len(tokens)} tokens total")
        
        for token in tokens:
            encrypted_value = token['encrypted_token']
            print(f"Token ID: {token['id']}")
            print(f"  User ID: {token['user_id']}")
            print(f"  Type: {token['token_type']}")
            print(f"  Encrypted value: '{encrypted_value}' (length: {len(encrypted_value)})")
            print(f"  Is empty: {encrypted_value == ''}")
            print(f"  Is None: {encrypted_value is None}")
            print("---")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()