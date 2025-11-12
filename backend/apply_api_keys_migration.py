#!/usr/bin/env python3
"""
Apply the user_api_keys migration to Supabase database.
Usage: uv run python apply_api_keys_migration.py
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent / ".env"
load_dotenv(env_path)

def apply_migration():
    """Apply the 006_user_api_keys.sql migration"""
    
    print("=" * 70)
    print("🔧 Applying User API Keys Migration")
    print("=" * 70)
    
    # Check for required environment variables
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("\n❌ Error: Missing required environment variables")
        print("   Please ensure .env contains:")
        print("   - SUPABASE_URL")
        print("   - SUPABASE_SERVICE_KEY")
        sys.exit(1)
    
    # Read migration file
    migration_file = Path(__file__).parent / "migrations" / "006_user_api_keys.sql"
    
    if not migration_file.exists():
        print(f"\n❌ Error: Migration file not found: {migration_file}")
        sys.exit(1)
    
    print(f"\n📄 Reading migration file: {migration_file.name}")
    with open(migration_file, 'r') as f:
        sql_content = f.read()
    
    print(f"   ✅ Migration file loaded ({len(sql_content)} characters)")
    
    # Try to apply using psycopg2 if available
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        print(f"\n🔌 Connecting to Supabase database...")
        
        # Parse Supabase URL to get connection details
        # Supabase URL format: https://xxxxx.supabase.co
        # Database URL format: postgresql://postgres:[password]@db.xxxxx.supabase.co:5432/postgres
        
        # Extract project ID from URL
        parsed = urlparse(supabase_url)
        project_id = parsed.hostname.split('.')[0]
        
        # Construct database URL
        # Note: You'll need to get the database password from Supabase dashboard
        db_password = os.getenv("SUPABASE_DB_PASSWORD")
        
        if not db_password:
            print("\n⚠️  SUPABASE_DB_PASSWORD not found in .env")
            print("   To apply migration automatically, add your database password to .env:")
            print("   SUPABASE_DB_PASSWORD=your-db-password")
            print("\n📋 Alternative: Apply migration manually using Supabase Dashboard")
            print("   1. Go to: https://supabase.com/dashboard/project/{project}/sql")
            print("   2. Copy and paste the SQL from: migrations/006_user_api_keys.sql")
            print("   3. Click 'Run'")
            sys.exit(0)
        
        db_url = f"postgresql://postgres:{db_password}@db.{project_id}.supabase.co:5432/postgres"
        
        # Connect and execute
        conn = psycopg2.connect(db_url)
        cursor = conn.cursor()
        
        print("   ✅ Connected to database")
        print("\n⚙️  Executing migration SQL...")
        
        cursor.execute(sql_content)
        conn.commit()
        
        print("   ✅ Migration executed successfully")
        
        # Verify tables were created
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('user_api_keys', 'api_usage_logs')
        """)
        tables = cursor.fetchall()
        
        print(f"\n✅ Verified tables created: {[t[0] for t in tables]}")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("🎉 Migration Applied Successfully!")
        print("=" * 70)
        print("\n📊 New tables created:")
        print("   - user_api_keys (stores encrypted API keys)")
        print("   - api_usage_logs (tracks API usage)")
        print("\n🔧 New functions created:")
        print("   - get_user_active_keys()")
        print("   - get_user_usage_stats()")
        print("\n🚀 Next steps:")
        print("   1. Start backend: uv run python run.py")
        print("   2. Test endpoints: curl http://localhost:8000/api/keys/providers")
        print("   3. View API docs: http://localhost:8000/docs")
        print()
        
    except ImportError:
        print("\n⚠️  psycopg2 not installed")
        print("   Installing psycopg2 for direct database access...")
        print("   Run: uv add psycopg2-binary")
        print("\n📋 Alternative: Apply migration manually")
        print("   Method 1 - Supabase Dashboard:")
        print("   1. Go to: https://supabase.com/dashboard")
        print("   2. Select your project")
        print("   3. Go to SQL Editor")
        print("   4. Copy and paste SQL from: migrations/006_user_api_keys.sql")
        print("   5. Click 'Run'")
        print("\n   Method 2 - Supabase CLI:")
        print("   1. Install: npm install -g supabase")
        print("   2. Login: supabase login")
        print("   3. Link project: supabase link --project-ref YOUR_PROJECT_ID")
        print("   4. Apply: supabase db push")
        print()
        
    except Exception as e:
        print(f"\n❌ Error applying migration: {e}")
        print("\n📋 Please apply migration manually using Supabase Dashboard:")
        print("   1. Go to: https://supabase.com/dashboard")
        print("   2. Select your project")
        print("   3. Go to SQL Editor")
        print("   4. Copy and paste SQL from: migrations/006_user_api_keys.sql")
        print("   5. Click 'Run'")
        print()
        sys.exit(1)


if __name__ == "__main__":
    apply_migration()
