"""
Quick reset script - interactive mode for easy use.
"""

import asyncio
from dotenv import load_dotenv

load_dotenv()

from app.services.pinecone_service import get_pinecone_service
from app.services.supabase_service import get_supabase_service


async def list_users():
    """List all users with their indexing status."""
    print("\n📋 Users in system:")
    print("=" * 80)
    
    supabase_service = get_supabase_service()
    
    # Get all users
    users_response = supabase_service.client.table("users").select("id, email, name, google_sub, created_at").execute()
    
    if not users_response.data or len(users_response.data) == 0:
        print("No users found")
        return []
    
    users = []
    for i, user in enumerate(users_response.data, 1):
        # Get job count
        jobs_response = supabase_service.client.table("ingestion_jobs").select("id, status").eq("user_id", user["id"]).eq("job_type", "rag_indexing").execute()
        
        job_count = len(jobs_response.data) if jobs_response.data else 0
        
        # Count by status
        pending = sum(1 for j in jobs_response.data if j["status"] == "pending") if jobs_response.data else 0
        processing = sum(1 for j in jobs_response.data if j["status"] == "processing") if jobs_response.data else 0
        completed = sum(1 for j in jobs_response.data if j["status"] == "completed") if jobs_response.data else 0
        failed = sum(1 for j in jobs_response.data if j["status"] == "failed") if jobs_response.data else 0
        
        print(f"\n{i}. {user.get('name', 'Unknown')}")
        print(f"   Email: {user.get('email', 'N/A')}")
        print(f"   Google Sub: {user.get('google_sub', 'N/A')}")
        print(f"   UUID: {user['id']}")
        print(f"   Jobs: {job_count} total (✓{completed} ⏳{processing} ⏸{pending} ✗{failed})")
        
        users.append(user)
    
    print("\n" + "=" * 80)
    return users


async def reset_user_interactive(user_id: str):
    """Reset user with confirmation."""
    print(f"\n🔄 Resetting indexing data for user: {user_id}")
    
    # Import the reset function
    from reset_indexing import reset_user_indexing
    
    # Show what will be deleted (dry run)
    print("\n📋 Preview (dry run):")
    await reset_user_indexing(user_id, dry_run=True)
    
    # Confirm
    print("\n⚠️  This will permanently delete:")
    print("  - All vectors in Pinecone")
    print("  - All indexing jobs")
    print("  - All indexed_at timestamps")
    
    confirm = input("\nType 'yes' to confirm: ").strip().lower()
    
    if confirm == "yes":
        print("\n🗑️  Deleting...")
        success = await reset_user_indexing(user_id, dry_run=False)
        
        if success:
            print("\n✅ Reset complete! User can now re-index documents.")
        else:
            print("\n❌ Reset failed. Check errors above.")
    else:
        print("\n❌ Cancelled")


async def main():
    print("=" * 80)
    print("ScholarMate - Quick Indexing Reset")
    print("=" * 80)
    
    while True:
        print("\nOptions:")
        print("1. List all users")
        print("2. Reset specific user")
        print("3. Exit")
        
        choice = input("\nChoice (1-3): ").strip()
        
        if choice == "1":
            users = await list_users()
            
        elif choice == "2":
            user_id = input("\nEnter user ID (Google sub or UUID): ").strip()
            
            if not user_id:
                print("❌ Invalid user ID")
                continue
            
            await reset_user_interactive(user_id)
            
        elif choice == "3":
            print("\n👋 Goodbye!")
            break
            
        else:
            print("❌ Invalid choice")


if __name__ == "__main__":
    asyncio.run(main())
