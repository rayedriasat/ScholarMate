"""Test script for tag functionality"""
import asyncio
import sys
from app.services.tag_service import get_tag_service
from app.utils.logging_config import get_logger

logger = get_logger(__name__)


async def test_tag_operations():
    """Test tag CRUD operations"""
    tag_service = get_tag_service()
    
    # Test user ID (replace with actual user ID)
    test_user_id = "test-user-123"
    
    print("\n=== Testing Tag Operations ===\n")
    
    try:
        # 1. Create a tag
        print("1. Creating tag 'Research'...")
        tag1 = await tag_service.create_tag(
            user_id=test_user_id,
            name="Research",
            color="#2196F3"
        )
        print(f"✓ Created tag: {tag1['id']} - {tag1['name']}")
        
        # 2. Try to create duplicate tag (should return existing)
        print("\n2. Creating duplicate tag 'Research'...")
        tag1_dup = await tag_service.create_tag(
            user_id=test_user_id,
            name="Research",
            color="#2196F3"
        )
        print(f"✓ Returned existing tag: {tag1_dup['id']} - {tag1_dup['name']}")
        assert tag1['id'] == tag1_dup['id'], "Should return same tag ID"
        
        # 3. Create another tag
        print("\n3. Creating tag 'Important'...")
        tag2 = await tag_service.create_tag(
            user_id=test_user_id,
            name="Important",
            color="#F44336"
        )
        print(f"✓ Created tag: {tag2['id']} - {tag2['name']}")
        
        # 4. Get all tags
        print("\n4. Getting all tags...")
        tags = await tag_service.get_tags_by_user(test_user_id)
        print(f"✓ Found {len(tags)} tags:")
        for tag in tags:
            print(f"  - {tag['name']} ({tag['color']}) - {tag['document_count']} docs")
        
        # 5. Update tag
        print("\n5. Updating tag 'Research' to 'Academic Research'...")
        updated_tag = await tag_service.update_tag(
            tag_id=tag1['id'],
            user_id=test_user_id,
            updates={"name": "Academic Research", "color": "#4CAF50"}
        )
        print(f"✓ Updated tag: {updated_tag['name']} ({updated_tag['color']})")
        
        # 6. Add tag to file
        print("\n6. Adding tag to file...")
        test_file_id = "test-file-123"
        file_tag = await tag_service.add_tag_to_file(
            user_id=test_user_id,
            file_id=test_file_id,
            tag_id=tag1['id']
        )
        print(f"✓ Added tag to file: {file_tag['id']}")
        
        # 7. Get tags for file
        print("\n7. Getting tags for file...")
        file_tags = await tag_service.get_tags_for_file(test_user_id, test_file_id)
        print(f"✓ File has {len(file_tags)} tags:")
        for tag in file_tags:
            print(f"  - {tag['name']}")
        
        # 8. Remove tag from file
        print("\n8. Removing tag from file...")
        await tag_service.remove_tag_from_file(
            user_id=test_user_id,
            file_id=test_file_id,
            tag_id=tag1['id']
        )
        print("✓ Removed tag from file")
        
        # 9. Delete tags
        print("\n9. Deleting tags...")
        await tag_service.delete_tag(tag1['id'], test_user_id)
        print(f"✓ Deleted tag: {tag1['id']}")
        
        await tag_service.delete_tag(tag2['id'], test_user_id)
        print(f"✓ Deleted tag: {tag2['id']}")
        
        # 10. Verify deletion
        print("\n10. Verifying deletion...")
        final_tags = await tag_service.get_tags_by_user(test_user_id)
        print(f"✓ Remaining tags: {len(final_tags)}")
        
        print("\n=== All Tests Passed! ===\n")
        
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


async def test_duplicate_prevention():
    """Test duplicate tag prevention"""
    tag_service = get_tag_service()
    test_user_id = "test-user-duplicate"
    
    print("\n=== Testing Duplicate Prevention ===\n")
    
    try:
        # Create tag
        print("1. Creating tag 'Test Tag'...")
        tag1 = await tag_service.create_tag(
            user_id=test_user_id,
            name="Test Tag",
            color="#2196F3"
        )
        print(f"✓ Created: {tag1['id']}")
        
        # Try variations
        print("\n2. Testing case variations...")
        variations = ["test tag", "TEST TAG", "  Test Tag  ", "Test Tag"]
        
        for variation in variations:
            print(f"  - Creating '{variation}'...")
            result = await tag_service.create_tag(
                user_id=test_user_id,
                name=variation,
                color="#2196F3"
            )
            assert result['id'] == tag1['id'], f"Should return same ID for '{variation}'"
            print(f"    ✓ Returned existing tag")
        
        # Verify only one tag exists
        tags = await tag_service.get_tags_by_user(test_user_id)
        assert len(tags) == 1, f"Should have 1 tag, found {len(tags)}"
        print(f"\n✓ Only 1 tag exists (correct)")
        
        # Cleanup
        await tag_service.delete_tag(tag1['id'], test_user_id)
        print("✓ Cleanup complete")
        
        print("\n=== Duplicate Prevention Tests Passed! ===\n")
        
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    print("Starting tag tests...")
    print("Note: Make sure backend is running and Supabase is configured")
    
    asyncio.run(test_tag_operations())
    asyncio.run(test_duplicate_prevention())
    
    print("\n✓ All tag tests completed successfully!")
