#!/usr/bin/env python3
"""
Script to apply SQL migrations to Supabase database
Usage: uv run python migrations/apply_migration.py <migration_file.sql>
"""
import sys
import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables from backend/.env
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


def apply_migration(migration_file: str):
    """Apply a SQL migration file to Supabase"""
    
    # Get Supabase credentials
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
        sys.exit(1)
    
    # Read migration file
    migration_path = Path(__file__).parent / migration_file
    if not migration_path.exists():
        print(f"❌ Error: Migration file not found: {migration_path}")
        sys.exit(1)
    
    print(f"📄 Reading migration: {migration_file}")
    with open(migration_path, 'r') as f:
        sql_content = f.read()
    
    # Create Supabase client
    print(f"🔌 Connecting to Supabase: {supabase_url}")
    client = create_client(supabase_url, supabase_key)
    
    # Execute SQL
    print("⚙️  Applying migration...")
    try:
        # Note: Supabase Python SDK doesn't have direct SQL execution
        # This is a placeholder - actual implementation would use psycopg2 or similar
        print("⚠️  Note: Direct SQL execution not supported by Supabase Python SDK")
        print("📋 Please apply this migration using one of these methods:")
        print("   1. Supabase Dashboard > SQL Editor")
        print("   2. psql command line tool")
        print("   3. Supabase CLI: supabase db push")
        print()
        print("📄 Migration file location:")
        print(f"   {migration_path.absolute()}")
        
    except Exception as e:
        print(f"❌ Error applying migration: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: uv run python migrations/apply_migration.py <migration_file.sql>")
        print("Example: uv run python migrations/apply_migration.py 001_initial_schema.sql")
        sys.exit(1)
    
    migration_file = sys.argv[1]
    apply_migration(migration_file)
