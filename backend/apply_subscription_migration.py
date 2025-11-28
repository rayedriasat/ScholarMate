"""
Apply subscription system migration to Supabase database

This script applies the 006_subscription_system.sql migration which:
- Adds subscription fields to users table
- Creates transactions table for payment history
- Sets up indexes and constraints
"""

import os
import sys
from pathlib import Path
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def apply_migration():
    """Apply the subscription system migration"""
    
    # Get Supabase credentials
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
        sys.exit(1)
    
    print("🔗 Connecting to Supabase...")
    client: Client = create_client(supabase_url, supabase_key)
    
    # Read migration file
    migration_file = Path(__file__).parent / "supabase_migrations" / "006_subscription_system.sql"
    
    if not migration_file.exists():
        print(f"❌ Error: Migration file not found at {migration_file}")
        sys.exit(1)
    
    print(f"📄 Reading migration file: {migration_file}")
    with open(migration_file, 'r', encoding='utf-8') as f:
        migration_sql = f.read()
    
    print("🚀 Applying migration...")
    try:
        # Execute the migration SQL
        # Note: Supabase Python client doesn't have direct SQL execution
        # You'll need to use psycopg2 or apply via Supabase dashboard
        print("\n" + "="*60)
        print("⚠️  MANUAL MIGRATION REQUIRED")
        print("="*60)
        print("\nThe Supabase Python client doesn't support direct SQL execution.")
        print("Please apply the migration using one of these methods:\n")
        print("1. Supabase Dashboard:")
        print("   - Go to your project's SQL Editor")
        print("   - Copy and paste the contents of:")
        print(f"     {migration_file}")
        print("   - Click 'Run'\n")
        print("2. PostgreSQL CLI:")
        print("   - Get your database connection string from Supabase")
        print("   - Run: psql <connection_string> -f backend/supabase_migrations/006_subscription_system.sql\n")
        print("3. Using psycopg2 (if installed):")
        print("   - Uncomment the psycopg2 code below in this script\n")
        print("="*60)
        
        # Alternative: Use psycopg2 if available
        try:
            import psycopg2
            
            # Parse connection string from Supabase URL
            # Format: postgresql://[user[:password]@][host][:port][/dbname]
            db_url = os.getenv("DATABASE_URL")
            if not db_url:
                print("\n💡 Tip: Set DATABASE_URL in .env for automatic migration")
                return
            
            print("\n🔄 Attempting automatic migration with psycopg2...")
            conn = psycopg2.connect(db_url)
            cursor = conn.cursor()
            
            # Execute migration
            cursor.execute(migration_sql)
            conn.commit()
            
            cursor.close()
            conn.close()
            
            print("✅ Migration applied successfully!")
            
        except ImportError:
            print("\n💡 Tip: Install psycopg2 for automatic migration:")
            print("   uv add psycopg2-binary")
        except Exception as e:
            print(f"\n❌ Error applying migration: {e}")
            print("Please apply manually using the methods above.")
    
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    apply_migration()
