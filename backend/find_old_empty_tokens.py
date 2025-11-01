#!/usr/bin/env python3
"""
Find tokens that might have been stored as empty before the fix
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
        # Get all tokens ordered by creation time
        print("Fetching all tokens ordered by creation time...")
        response = supabase.table("encrypted_tokens").select("*").order("created_at").execute()
        tokens = response.data
        
        print(f"Found {len(tokens)} tokens total")
        print("\nToken analysis:")
        print("-" * 80)
        
        for i, token in enumerate(tokens):
            encrypted_value = token['encrypted_token']
            created_at = token['created_at']
            
            print(f"{i+1}. Token ID: {token['id'][:8]}...")
            print(f"   User: {token['user_id'][:8]}...")
            print(f"   Type: {token['token_type']}")
            print(f"   Created: {created_at}")
            print(f"   Length: {len(encrypted_value)}")
            print(f"   Value: '{encrypted_value[:50]}{'...' if len(encrypted_value) > 50 else ''}'")
            
            # Check if this looks like an empty token
            if len(encrypted_value) == 0:
                print("   *** EMPTY TOKEN ***")
            elif encrypted_value.strip() == "":
                print("   *** WHITESPACE ONLY TOKEN ***")
            elif len(encrypted_value) < 20:
                print("   *** SUSPICIOUSLY SHORT TOKEN ***")
            
            print()
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()