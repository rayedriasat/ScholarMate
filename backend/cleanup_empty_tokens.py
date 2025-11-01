#!/usr/bin/env python3
"""
Clean up empty tokens from the database
"""
import os
import sys
from dotenv import load_dotenv
from supabase import create_client

def main():
    load_dotenv()
    
    client = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_KEY'))
    
    try:
        # Find tokens with empty encrypted_token
        print("Finding empty tokens...")
        response = client.table('encrypted_tokens').select('*').execute()
        all_tokens = response.data
        
        empty_tokens = [token for token in all_tokens if len(token['encrypted_token']) == 0]
        
        print(f"Found {len(empty_tokens)} empty tokens:")
        for token in empty_tokens:
            print(f"  - {token['token_type']} for user {token['user_id']} (ID: {token['id']})")
        
        if empty_tokens:
            confirm = input(f"\nDelete {len(empty_tokens)} empty tokens? (y/N): ")
            if confirm.lower() == 'y':
                for token in empty_tokens:
                    client.table('encrypted_tokens').delete().eq('id', token['id']).execute()
                    print(f"Deleted {token['token_type']} token {token['id']}")
                print(f"Successfully deleted {len(empty_tokens)} empty tokens")
            else:
                print("Cancelled")
        else:
            print("No empty tokens found")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()