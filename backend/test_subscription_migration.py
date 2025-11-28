"""
Test script to verify subscription migration SQL syntax

This script validates that the migration file:
1. Can be read successfully
2. Contains all required components
3. Has valid SQL syntax (basic checks)
"""

import re
from pathlib import Path

def test_migration_file():
    """Test the subscription migration file"""
    
    migration_file = Path(__file__).parent / "supabase_migrations" / "006_subscription_system.sql"
    
    print("🔍 Testing subscription migration file...")
    print(f"📄 File: {migration_file}\n")
    
    # Check file exists
    if not migration_file.exists():
        print("❌ FAIL: Migration file not found")
        return False
    
    print("✅ File exists")
    
    # Read file
    with open(migration_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"✅ File readable ({len(content)} characters)")
    
    # Check for required components
    required_components = [
        # Users table modifications
        ("ALTER TABLE users ADD COLUMN", "Users table subscription fields"),
        ("subscription_status", "Subscription status column"),
        ("subscription_activated_at", "Subscription activated timestamp"),
        ("subscription_expires_at", "Subscription expires timestamp"),
        ("CHECK.*subscription_status.*IN.*'free'.*'premium'", "Subscription status constraint"),
        
        # Transactions table
        ("CREATE TABLE.*transactions", "Transactions table creation"),
        ("transaction_id.*VARCHAR.*UNIQUE", "Transaction ID column"),
        ("user_id.*UUID.*REFERENCES users", "User ID foreign key"),
        ("payment_method.*VARCHAR", "Payment method column"),
        ("amount.*DECIMAL", "Amount column"),
        ("currency.*VARCHAR", "Currency column"),
        ("status.*VARCHAR", "Status column"),
        ("metadata.*JSONB", "Metadata column"),
        ("created_at.*TIMESTAMP", "Created timestamp"),
        ("verified_at.*TIMESTAMP", "Verified timestamp"),
        
        # Constraints
        ("CHECK.*payment_method.*IN.*'bkash'.*'debit_card'.*'credit_card'", "Payment method constraint"),
        ("CHECK.*status.*IN.*'pending'.*'success'.*'failed'", "Status constraint"),
        ("CHECK.*amount.*>.*0", "Amount positive constraint"),
        
        # Indexes
        ("CREATE INDEX.*idx_users_subscription_status", "Users subscription status index"),
        ("CREATE INDEX.*idx_transactions_user_id", "Transactions user ID index"),
        ("CREATE INDEX.*idx_transactions_transaction_id", "Transactions transaction ID index"),
        ("CREATE INDEX.*idx_transactions_status", "Transactions status index"),
        ("CREATE INDEX.*idx_transactions_created_at", "Transactions created_at index"),
        
        # RLS
        ("ALTER TABLE transactions ENABLE ROW LEVEL SECURITY", "RLS enabled on transactions"),
        
        # Comments
        ("COMMENT ON TABLE transactions", "Table comment"),
        ("COMMENT ON COLUMN users.subscription_status", "Column comments"),
    ]
    
    print("\n🔍 Checking required components:")
    all_passed = True
    
    for pattern, description in required_components:
        if re.search(pattern, content, re.IGNORECASE | re.DOTALL):
            print(f"  ✅ {description}")
        else:
            print(f"  ❌ {description} - NOT FOUND")
            all_passed = False
    
    # Check for common SQL syntax issues
    print("\n🔍 Checking SQL syntax:")
    
    syntax_checks = [
        (r";\s*$", "Ends with semicolon", True),
        (r"--.*\n", "Has comments", True),
        (r"IF NOT EXISTS", "Uses IF NOT EXISTS for safety", True),
        (r"CASCADE", "Uses CASCADE for foreign keys", True),
        (r"DEFAULT", "Has default values", True),
    ]
    
    for pattern, description, should_exist in syntax_checks:
        found = bool(re.search(pattern, content, re.MULTILINE))
        if found == should_exist:
            print(f"  ✅ {description}")
        else:
            print(f"  ⚠️  {description} - {'NOT FOUND' if should_exist else 'FOUND'}")
    
    # Count statements
    create_statements = len(re.findall(r'\bCREATE\b', content, re.IGNORECASE))
    alter_statements = len(re.findall(r'\bALTER\b', content, re.IGNORECASE))
    index_statements = len(re.findall(r'\bCREATE INDEX\b', content, re.IGNORECASE))
    
    print(f"\n📊 Statement counts:")
    print(f"  - CREATE statements: {create_statements}")
    print(f"  - ALTER statements: {alter_statements}")
    print(f"  - INDEX statements: {index_statements}")
    
    # Final result
    print("\n" + "="*60)
    if all_passed:
        print("✅ ALL CHECKS PASSED - Migration file is valid!")
        print("="*60)
        print("\n📝 Next steps:")
        print("1. Apply the migration using one of the methods in SUBSCRIPTION_MIGRATION_GUIDE.md")
        print("2. Verify the migration with the SQL queries in the guide")
        print("3. Proceed to Task 2: Implement backend payment gateway abstraction layer")
        return True
    else:
        print("❌ SOME CHECKS FAILED - Please review the migration file")
        print("="*60)
        return False

if __name__ == "__main__":
    success = test_migration_file()
    exit(0 if success else 1)
