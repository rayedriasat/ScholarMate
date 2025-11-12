#!/usr/bin/env python3
"""
Simple migration applier using Supabase client.
This creates the tables using the Supabase service.
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

# Load environment
env_path = Path(__file__).parent / ".env"
load_dotenv(env_path)

def apply_migration():
    """Apply migration by creating tables through Supabase client"""
    
    print("=" * 70)
    print("🔧 Applying User API Keys Migration")
    print("=" * 70)
    
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("\n❌ Error: Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in .env")
        sys.exit(1)
    
    print(f"\n📄 Migration file: migrations/006_user_api_keys.sql")
    
    # Read migration SQL
    migration_file = Path(__file__).parent / "migrations" / "006_user_api_keys.sql"
    with open(migration_file, 'r') as f:
        sql_content = f.read()
    
    print(f"   ✅ Loaded ({len(sql_content)} characters)")
    
    print("\n" + "=" * 70)
    print("📋 MANUAL MIGRATION REQUIRED")
    print("=" * 70)
    
    print("\n⚠️  The Supabase Python SDK doesn't support direct SQL execution.")
    print("   Please apply this migration using the Supabase Dashboard:\n")
    
    print("🔗 Steps:")
    print("   1. Open: https://supabase.com/dashboard")
    print("   2. Select your project")
    print("   3. Go to: SQL Editor (left sidebar)")
    print("   4. Click: 'New Query'")
    print("   5. Copy the SQL below and paste it")
    print("   6. Click: 'Run' (or press Ctrl+Enter)")
    
    print("\n" + "=" * 70)
    print("📄 SQL TO COPY:")
    print("=" * 70)
    print()
    print(sql_content)
    print()
    print("=" * 70)
    
    print("\n✅ After running the SQL, you'll have:")
    print("   - user_api_keys table (encrypted API keys)")
    print("   - api_usage_logs table (usage tracking)")
    print("   - Helper functions for queries")
    
    print("\n🚀 Then you can:")
    print("   1. Start backend: uv run python run.py")
    print("   2. Test: curl http://localhost:8000/api/keys/providers")
    print("   3. View docs: http://localhost:8000/docs")
    print()
    
    # Save SQL to a temp file for easy copying
    output_file = Path(__file__).parent / "migration_to_apply.sql"
    with open(output_file, 'w') as f:
        f.write(sql_content)
    
    print(f"💾 SQL also saved to: {output_file}")
    print("   You can copy from this file if needed.")
    print()


if __name__ == "__main__":
    apply_migration()
