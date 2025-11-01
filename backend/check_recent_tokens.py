#!/usr/bin/env python3
"""
Check for recently created tokens
"""
import os
from dotenv import load_dotenv
from supabase import create_client
from datetime import datetime, timedelta

def main():
    load_dotenv()
    
    client = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_KEY'))
    
    # Check for any tokens created in the last 2 hours
    recent_time = (datetime.utcnow() - timedelta(hours=2)).isoformat()
    response = client.table('encrypted_tokens').select('*').gte('created_at', recent_time).execute()
    
    print(f'Tokens created in last 2 hours: {len(response.data)}')
    for token in response.data:
        encrypted_value = token["encrypted_token"]
        print(f'  {token["token_type"]}: length={len(encrypted_value)}')
        if len(encrypted_value) == 0:
            print(f'    *** EMPTY TOKEN FOUND ***')
        elif len(encrypted_value) < 50:
            print(f'    Value: "{encrypted_value}"')
        else:
            print(f'    Value: "{encrypted_value[:30]}..."')

if __name__ == "__main__":
    main()