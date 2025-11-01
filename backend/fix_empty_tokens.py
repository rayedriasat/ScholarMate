#!/usr/bin/env python3
"""
Script to clean up empty encrypted tokens in the database.
This removes tokens that were stored as empty strings due to the bug.
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
        # Find all empty tokens
        print("Finding empty encrypted tokens...")
        response = supabase.table("encrypted_tokens").select("*").eq("encrypted_token", "").execute()
        empty_tokens = response.data
        
        print(f"Found {len(empty_tokens)} empty tokens")
        
        if empty_tokens:
            # Delete empty tokens
            print("Deleting empty tokens...")
            for token in empty_tokens:
                print(f"  Deleting {token['token_type']} token for user {token['user_id']}")
                supabase.table("encrypted_tokens").delete().eq("id", token["id"]).execute()
            
            print(f"Successfully deleted {len(empty_tokens)} empty tokens")
        else:
            print("No empty tokens found")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()