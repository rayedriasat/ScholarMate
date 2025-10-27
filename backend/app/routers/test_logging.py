"""Test endpoints for logging and error handling"""
from fastapi import APIRouter, HTTPException, status
from ..utils.logging_config import get_logger

router = APIRouter(prefix="/api/test", tags=["testing"])
logger = get_logger(__name__)


@router.get("/success")
async def test_success():
    """Test successful request logging"""
    logger.info("Test success endpoint called")
    return {"message": "Success!", "status": "ok"}


@router.get("/error-400")
async def test_error_400():
    """Test 400 error handling"""
    logger.warning("Test 400 error endpoint called")
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="This is a test 400 error"
    )


@router.get("/error-500")
async def test_error_500():
    """Test 500 error handling"""
    logger.warning("Test 500 error endpoint called - about to raise exception")
    raise Exception("This is a test unhandled exception")


@router.post("/validation-error")
async def test_validation_error(required_field: str):
    """Test validation error handling (call without required_field to trigger)"""
    logger.info("Test validation endpoint called", extra={"required_field": required_field})
    return {"message": "Validation passed", "field": required_field}
