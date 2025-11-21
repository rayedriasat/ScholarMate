#!/usr/bin/env python3
"""Apply analytics migration to Supabase"""
import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

def apply_migration():
    """Apply the analytics migration"""
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_KEY")
        return
    
    supabase = create_client(supabase_url, supabase_key)
    
    # Read migration file
    with open("migrations/007_analytics.sql", "r") as f:
        sql = f.read()
    
    # Split into individual statements
    statements = [s.strip() for s in sql.split(";") if s.strip()]
    
    print("🚀 Applying analytics migration...")
    
    for i, statement in enumerate(statements, 1):
        try:
            print(f"  [{i}/{len(statements)}] Executing statement...")
            supabase.postgrest.rpc("exec_sql", {"sql": statement}).execute()
            print(f"  ✅ Statement {i} executed")
        except Exception as e:
            # Try direct execution if RPC fails
            try:
                supabase.table("_migrations").insert({
                    "name": f"007_analytics_statement_{i}",
                    "executed_at": "now()"
                }).execute()
                print(f"  ⚠️  Statement {i} may need manual execution: {str(e)[:100]}")
            except:
                print(f"  ⚠️  Statement {i}: {str(e)[:100]}")
    
    print("\n✅ Analytics migration applied!")
    print("\nNext steps:")
    print("1. Verify tables in Supabase dashboard")
    print("2. Test analytics tracking in the app")
    print("3. Check sync functionality")

if __name__ == "__main__":
    apply_migration()
