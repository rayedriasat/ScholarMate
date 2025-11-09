"""
Reset indexing data for a user or entire system.
Use this to clean up failed/stuck indexing jobs and vector data.

Usage:
    # Reset specific user (recommended)
    python reset_indexing.py --user-id <google_user_id_or_uuid>
    
    # Reset ALL users (dangerous!)
    python reset_indexing.py --all --confirm
    
    # Dry run (see what would be deleted)
    python reset_indexing.py --user-id <user_id> --dry-run
"""

import os
import sys
import argparse
import asyncio
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from app.services.pinecone_service import get_pinecone_service
from app.services.supabase_service import get_supabase_service


async def reset_user_indexing(user_id: str, dry_run: bool = False):
    """
    Reset all indexing data for a specific user.
    
    This will:
    1. Delete all vectors in user's Pinecone namespace
    2. Delete all ingestion jobs for user
    3. Clear indexed_at timestamps on files
    
    Args:
        user_id: User ID (Google sub or Supabase UUID)
        dry_run: If True, only show what would be deleted
    """
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Resetting indexing data for user: {user_id}")
    print("=" * 60)
    
    try:
        # Initialize services
        pinecone_service = get_pinecone_service()
        supabase_service = get_supabase_service()
        
        # Step 1: Get or resolve user UUID
        print("\n1. Resolving user ID...")
        try:
            user_response = supabase_service.client.table("users").select("id, email, name, google_sub").eq("google_sub", user_id).execute()
            
            if not user_response.data or len(user_response.data) == 0:
                # Try as UUID
                user_response = supabase_service.client.table("users").select("id, email, name, google_sub").eq("id", user_id).execute()
                
                if not user_response.data or len(user_response.data) == 0:
                    print(f"❌ User not found: {user_id}")
                    return False
            
            user_data = user_response.data[0]
            user_uuid = user_data["id"]
            user_email = user_data.get("email", "N/A")
            user_name = user_data.get("name", "N/A")
            google_sub = user_data.get("google_sub", "N/A")
            
            print(f"✓ Found user:")
            print(f"  - UUID: {user_uuid}")
            print(f"  - Email: {user_email}")
            print(f"  - Name: {user_name}")
            print(f"  - Google Sub: {google_sub}")
            
        except Exception as e:
            print(f"❌ Error resolving user: {e}")
            return False
        
        # Step 2: Get Pinecone namespace stats
        print("\n2. Checking Pinecone namespace...")
        try:
            stats = pinecone_service.get_namespace_stats(user_uuid)
            namespace = stats["namespace"]
            vector_count = stats["document_count"]
            
            print(f"✓ Namespace: {namespace}")
            print(f"  - Vectors: {vector_count}")
            
            if vector_count > 0:
                if not dry_run:
                    print(f"  - Deleting {vector_count} vectors...")
                    success = pinecone_service.delete_namespace(user_uuid)
                    if success:
                        print(f"  ✓ Deleted all vectors from namespace")
                    else:
                        print(f"  ⚠ Failed to delete namespace (may not exist)")
                else:
                    print(f"  [DRY RUN] Would delete {vector_count} vectors")
            else:
                print(f"  - No vectors to delete")
                
        except Exception as e:
            print(f"⚠ Error with Pinecone: {e}")
        
        # Step 3: Get ingestion jobs
        print("\n3. Checking ingestion jobs...")
        try:
            jobs_response = supabase_service.client.table("ingestion_jobs").select("id, status, job_type, created_at").eq("user_id", user_uuid).eq("job_type", "rag_indexing").execute()
            
            job_count = len(jobs_response.data) if jobs_response.data else 0
            print(f"✓ Found {job_count} indexing jobs")
            
            if job_count > 0:
                # Show job statuses
                status_counts = {}
                for job in jobs_response.data:
                    status = job["status"]
                    status_counts[status] = status_counts.get(status, 0) + 1
                
                for status, count in status_counts.items():
                    print(f"  - {status}: {count}")
                
                if not dry_run:
                    print(f"  - Deleting {job_count} jobs...")
                    for job in jobs_response.data:
                        supabase_service.client.table("ingestion_jobs").delete().eq("id", job["id"]).execute()
                    print(f"  ✓ Deleted all indexing jobs")
                else:
                    print(f"  [DRY RUN] Would delete {job_count} jobs")
            else:
                print(f"  - No jobs to delete")
                
        except Exception as e:
            print(f"⚠ Error with ingestion jobs: {e}")
        
        # Step 4: Clear indexed_at timestamps on files
        print("\n4. Checking indexed files...")
        try:
            files_response = supabase_service.client.table("files").select("id, name, indexed_at").eq("user_id", user_uuid).not_.is_("indexed_at", "null").execute()
            
            indexed_count = len(files_response.data) if files_response.data else 0
            print(f"✓ Found {indexed_count} indexed files")
            
            if indexed_count > 0:
                for file in files_response.data[:5]:  # Show first 5
                    print(f"  - {file['name']}")
                if indexed_count > 5:
                    print(f"  ... and {indexed_count - 5} more")
                
                if not dry_run:
                    print(f"  - Clearing indexed_at timestamps...")
                    supabase_service.client.table("files").update({"indexed_at": None}).eq("user_id", user_uuid).execute()
                    print(f"  ✓ Cleared timestamps on {indexed_count} files")
                else:
                    print(f"  [DRY RUN] Would clear timestamps on {indexed_count} files")
            else:
                print(f"  - No indexed files")
                
        except Exception as e:
            print(f"⚠ Error with files: {e}")
        
        print("\n" + "=" * 60)
        if dry_run:
            print("✓ Dry run complete - no changes made")
        else:
            print("✓ Reset complete!")
        print("\nUser can now re-index their documents from scratch.")
        return True
        
    except Exception as e:
        print(f"\n❌ Error during reset: {e}")
        import traceback
        traceback.print_exc()
        return False


async def reset_all_indexing(confirm: bool = False, dry_run: bool = False):
    """
    Reset ALL indexing data for ALL users.
    
    WARNING: This is destructive and should only be used in development!
    """
    if not confirm and not dry_run:
        print("\n⚠️  WARNING: This will delete ALL indexing data for ALL users!")
        print("This operation cannot be undone.")
        print("\nTo confirm, run with --confirm flag:")
        print("  python reset_indexing.py --all --confirm")
        return False
    
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Resetting ALL indexing data")
    print("=" * 60)
    
    try:
        supabase_service = get_supabase_service()
        
        # Get all users
        print("\n1. Getting all users...")
        users_response = supabase_service.client.table("users").select("id, email, google_sub").execute()
        user_count = len(users_response.data) if users_response.data else 0
        
        print(f"✓ Found {user_count} users")
        
        if user_count == 0:
            print("No users to reset")
            return True
        
        # Reset each user
        success_count = 0
        for i, user in enumerate(users_response.data, 1):
            print(f"\n--- User {i}/{user_count} ---")
            success = await reset_user_indexing(user["id"], dry_run=dry_run)
            if success:
                success_count += 1
        
        print("\n" + "=" * 60)
        print(f"✓ Reset {success_count}/{user_count} users")
        
        if not dry_run:
            print("\n⚠️  All indexing data has been deleted!")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error during reset: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    parser = argparse.ArgumentParser(
        description="Reset indexing data for ScholarMate",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Reset specific user (recommended)
  python reset_indexing.py --user-id 111828646872592591995
  
  # Dry run (see what would be deleted)
  python reset_indexing.py --user-id 111828646872592591995 --dry-run
  
  # Reset ALL users (dangerous!)
  python reset_indexing.py --all --confirm
        """
    )
    
    parser.add_argument(
        "--user-id",
        help="User ID (Google sub or Supabase UUID) to reset"
    )
    
    parser.add_argument(
        "--all",
        action="store_true",
        help="Reset ALL users (requires --confirm)"
    )
    
    parser.add_argument(
        "--confirm",
        action="store_true",
        help="Confirm destructive operation"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be deleted without actually deleting"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.user_id and not args.all:
        parser.print_help()
        print("\n❌ Error: Must specify either --user-id or --all")
        sys.exit(1)
    
    if args.user_id and args.all:
        print("❌ Error: Cannot specify both --user-id and --all")
        sys.exit(1)
    
    # Execute reset
    if args.user_id:
        success = await reset_user_indexing(args.user_id, dry_run=args.dry_run)
    else:
        success = await reset_all_indexing(confirm=args.confirm, dry_run=args.dry_run)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    asyncio.run(main())
