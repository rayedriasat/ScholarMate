#!/usr/bin/env python3
"""
Direct migration applier using Supabase REST API.
This will apply the migration by executing SQL through Supabase.
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import requests

# Load environment
env_path = Path(__file__).parent / ".env"
load_dotenv(env_path)

def apply_migration():
    """Apply migration using Supabase REST API"""
    
    print("=" * 70)
    print("🔧 Applying User API Keys Migration to Supabase")
    print("=" * 70)
    
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("\n❌ Error: Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in .env")
        sys.exit(1)
    
    # Extract project ref from URL
    project_ref = supabase_url.replace("https://", "").split(".")[0]
    
    print(f"\n📄 Project: {project_ref}")
    print(f"   URL: {supabase_url}")
    
    # Read migration SQL
    migration_file = Path(__file__).parent / "migrations" / "006_user_api_keys.sql"
    with open(migration_file, 'r') as f:
        sql_content = f.read()
    
    print(f"\n✅ Migration file loaded ({len(sql_content)} characters)")
    
    print("\n" + "=" * 70)
    print("⚠️  MANUAL STEP REQUIRED")
    print("=" * 70)
    
    print("\nThe Supabase REST API doesn't support direct SQL execution.")
    print("You need to apply this migration through the Supabase Dashboard.\n")
    
    print("🔗 Quick Steps (30 seconds):")
    print(f"\n1. Open: https://supabase.com/dashboard/project/{project_ref}/sql/new")
    print("\n2. Copy the SQL below:")
    print("\n" + "=" * 70)
    print(sql_content)
    print("=" * 70)
    
    print("\n3. Paste into the SQL Editor")
    print("4. Click 'Run' (or press Ctrl+Enter)")
    print("5. Wait for 'Success' message")
    
    print("\n✅ After running, you'll have:")
    print("   - user_api_keys table")
    print("   - api_usage_logs table")
    print("   - Helper functions")
    
    print("\n🚀 Then test:")
    print("   1. Refresh your Flutter app")
    print("   2. Go to Settings → API Keys")
    print("   3. Tap '+ Add Key'")
    print("   4. Add a GROQ key (free)")
    
    print("\n💾 SQL also saved to: backend/migration_to_apply.sql")
    print()
    
    # Also save to a file for easy copying
    output_file = Path(__file__).parent / "migration_to_apply.sql"
    with open(output_file, 'w') as f:
        f.write(sql_content)
    
    print(f"✅ You can also copy from: {output_file}")
    print()


if __name__ == "__main__":
    apply_migration()
