#!/usr/bin/env python3
"""
Test script to verify the authentication flow
"""
import os
import sys
from dotenv import load_dotenv
from supabase import create_client

def main():
    load_dotenv()
    
    client = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_KEY'))
    
    try:
        # List all users
        print("=== All Users ===")
        response = client.table('users').select('*').execute()
        users = response.data
        
        for user in users:
            print(f"User: {user['email']} (Google Sub: {user['google_sub']})")
            print(f"  ID: {user['id']}")
            print(f"  Name: {user.get('name', 'N/A')}")
            print(f"  Created: {user['created_at']}")
            
            # Get tokens for this user
            token_response = client.table('encrypted_tokens').select('*').eq('user_id', user['id']).execute()
            tokens = token_response.data
            
            print(f"  Tokens: {len(tokens)}")
            for token in tokens:
                print(f"    - {token['token_type']}: {len(token['encrypted_token'])} chars")
            print()
        
        print(f"Total users: {len(users)}")
        
        # Check for duplicate users (same google_sub)
        google_subs = [user['google_sub'] for user in users]
        duplicates = set([x for x in google_subs if google_subs.count(x) > 1])
        
        if duplicates:
            print(f"\n=== Duplicate Google Subs Found ===")
            for dup in duplicates:
                dup_users = [u for u in users if u['google_sub'] == dup]
                print(f"Google Sub {dup} has {len(dup_users)} users:")
                for u in dup_users:
                    print(f"  - {u['email']} (ID: {u['id']}, Created: {u['created_at']})")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()