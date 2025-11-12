"""
Test script to diagnose metadata extraction issues.
Run with: uv run python test_metadata_endpoint.py
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

print("=" * 60)
print("METADATA EXTRACTION DIAGNOSTIC")
print("=" * 60)

# Check environment variables
print("\n1. Checking Environment Variables:")
print("-" * 60)

required_vars = [
    "GOOGLE_CLIENT_ID",
    "GOOGLE_CLIENT_SECRET",
    "SUPABASE_URL",
    "SUPABASE_SERVICE_KEY",
    "ENCRYPTION_KEY"
]

missing_vars = []
for var in required_vars:
    value = os.getenv(var)
    if value:
        # Show first 10 chars only for security
        display_value = value[:10] + "..." if len(value) > 10 else value
        print(f"✓ {var}: {display_value}")
    else:
        print(f"✗ {var}: NOT SET")
        missing_vars.append(var)

if missing_vars:
    print(f"\n⚠️  Missing required environment variables: {', '.join(missing_vars)}")
    print("\nPlease set these in backend/.env file")
    sys.exit(1)

# Test imports
print("\n2. Checking Python Dependencies:")
print("-" * 60)

try:
    import pypdf
    print(f"✓ pypdf: {pypdf.__version__}")
except ImportError as e:
    print(f"✗ pypdf: NOT INSTALLED - {e}")

try:
    import requests
    print(f"✓ requests: {requests.__version__}")
except ImportError as e:
    print(f"✗ requests: NOT INSTALLED - {e}")

try:
    from cryptography.fernet import Fernet
    print("✓ cryptography: installed")
except ImportError as e:
    print(f"✗ cryptography: NOT INSTALLED - {e}")

try:
    from supabase import create_client
    print("✓ supabase: installed")
except ImportError as e:
    print(f"✗ supabase: NOT INSTALLED - {e}")

# Test service initialization
print("\n3. Testing Service Initialization:")
print("-" * 60)

try:
    from app.services.encryption_service import get_encryption_service
    encryption_service = get_encryption_service()
    print("✓ Encryption service initialized")
except Exception as e:
    print(f"✗ Encryption service failed: {e}")

try:
    from app.services.supabase_service import get_supabase_service
    supabase_service = get_supabase_service()
    print("✓ Supabase service initialized")
except Exception as e:
    print(f"✗ Supabase service failed: {e}")

try:
    from app.services.drive_service import get_drive_service
    drive_service = get_drive_service()
    print("✓ Drive service initialized")
except Exception as e:
    print(f"✗ Drive service failed: {e}")
    print(f"   Error details: {str(e)}")

# Test metadata service
print("\n4. Testing Metadata Service:")
print("-" * 60)

try:
    from app.services.metadata_service import MetadataService
    print("✓ MetadataService imported successfully")
    
    # Test with a dummy PDF (minimal valid PDF)
    dummy_pdf = b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>\nendobj\nxref\n0 4\n0000000000 65535 f\n0000000009 00000 n\n0000000058 00000 n\n0000000115 00000 n\ntrailer\n<< /Size 4 /Root 1 0 R >>\nstartxref\n190\n%%EOF"
    
    metadata = MetadataService.extract_from_pdf_info(
        dummy_pdf,
        "test.pdf",
        "test_id"
    )
    print(f"✓ Metadata extraction works")
    print(f"   Title: {metadata.title}")
    print(f"   File ID: {metadata.file_id}")
    
except Exception as e:
    print(f"✗ Metadata extraction failed: {e}")
    import traceback
    print(traceback.format_exc())

print("\n" + "=" * 60)
print("DIAGNOSTIC COMPLETE")
print("=" * 60)

print("\nIf all checks pass, the metadata extraction should work.")
print("If any checks fail, fix those issues first.")
print("\nCommon fixes:")
print("- Missing env vars: Copy .env.template to .env and fill in values")
print("- Missing dependencies: Run 'uv sync' in backend directory")
print("- Service initialization errors: Check the error details above")
