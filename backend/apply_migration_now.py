"""Apply subscription migration using psycopg2"""
import psycopg2

# Database connection string (password URL-encoded: @ becomes %40)
DATABASE_URL = "postgresql://postgres.rqyzgfgdsedvohxyyqho:Anas%402003@aws-0-ap-south-1.pooler.supabase.com:6543/postgres"

print("🔗 Connecting to database...")
conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

print("📄 Reading migration file...")
with open('supabase_migrations/006_subscription_system.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

print("🚀 Applying migration...")
cursor.execute(sql)
conn.commit()

cursor.close()
conn.close()

print("✅ Migration applied successfully!")
