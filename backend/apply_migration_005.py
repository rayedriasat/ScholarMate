"""Apply migration 005 - Fix file_id type"""
import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not supabase_url or not supabase_key:
    print("Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set")
    exit(1)

client = create_client(supabase_url, supabase_key)

# Read migration SQL
with open("migrations/005_fix_file_id_type.sql", "r") as f:
    sql = f.read()

print("Applying migration 005...")
print(sql)

# Execute SQL
try:
    # Split by semicolon and execute each statement
    statements = [s.strip() for s in sql.split(";") if s.strip()]
    for stmt in statements:
        print(f"\nExecuting: {stmt[:100]}...")
        result = client.rpc("exec_sql", {"sql": stmt}).execute()
        print("✓ Success")
    
    print("\n✓ Migration 005 applied successfully!")
except Exception as e:
    print(f"\n✗ Error: {e}")
    exit(1)
