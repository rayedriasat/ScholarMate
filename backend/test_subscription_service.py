"""Tests for SubscriptionService"""
import pytest
import asyncio
from datetime import datetime, timedelta
from unittest.mock import Mock, AsyncMock, patch
from app.services.subscription_service import SubscriptionService


class TestSubscriptionService:
    """Test suite for SubscriptionService"""
    
    @pytest.fixture
    def mock_supabase_client(self):
        """Create mock Supabase client"""
        client = Mock()
        client.table = Mock()
        return client
    
    @pytest.fixture
    def subscription_service(self, mock_supabase_client):
        """Create SubscriptionService with mock client"""
        return SubscriptionService(supabase_client=mock_supabase_client)
    
    @pytest.mark.asyncio
    async def test_activate_premium_success(self, subscription_service, mock_supabase_client):
        """Test successful premium activation"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        transaction_id = "TXN_ABC123"
        duration_days = 365
        
        # Mock successful database update
        mock_response = Mock()
        mock_response.data = [{
            "id": user_id,
            "subscription_status": "premium",
            "subscription_activated_at": datetime.utcnow().isoformat(),
            "subscription_expires_at": (datetime.utcnow() + timedelta(days=duration_days)).isoformat()
        }]
        
        mock_table = Mock()
        mock_table.update = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.activate_premium(
            user_id=user_id,
            transaction_id=transaction_id,
            duration_days=duration_days
        )
        
        # Assert
        assert result["plan"] == "premium"
        assert result["is_active"] is True
        assert "activated_at" in result
        assert "expires_at" in result
        
        # Verify database was called correctly
        mock_supabase_client.table.assert_called_with("users")
        mock_table.update.assert_called_once()
        update_data = mock_table.update.call_args[0][0]
        assert update_data["subscription_status"] == "premium"
        assert "subscription_activated_at" in update_data
        assert "subscription_expires_at" in update_data
    
    @pytest.mark.asyncio
    async def test_activate_premium_user_not_found(self, subscription_service, mock_supabase_client):
        """Test premium activation fails when user not found"""
        # Arrange
        user_id = "nonexistent-user-id"
        transaction_id = "TXN_ABC123"
        
        # Mock empty response (user not found)
        mock_response = Mock()
        mock_response.data = []
        
        mock_table = Mock()
        mock_table.update = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act & Assert
        with pytest.raises(ValueError, match="User not found"):
            await subscription_service.activate_premium(
                user_id=user_id,
                transaction_id=transaction_id
            )
    
    @pytest.mark.asyncio
    async def test_get_subscription_status_premium_active(self, subscription_service, mock_supabase_client):
        """Test getting subscription status for active premium user"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        from datetime import timezone
        activated_at = datetime.now(timezone.utc) - timedelta(days=30)
        expires_at = datetime.now(timezone.utc) + timedelta(days=335)
        
        # Mock database response
        mock_response = Mock()
        mock_response.data = [{
            "subscription_status": "premium",
            "subscription_activated_at": activated_at.isoformat(),
            "subscription_expires_at": expires_at.isoformat()
        }]
        
        mock_table = Mock()
        mock_table.select = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.get_subscription_status(user_id)
        
        # Assert
        assert result["plan"] == "premium"
        assert result["is_active"] is True
        assert result["activated_at"] == activated_at.isoformat()
        assert result["expires_at"] == expires_at.isoformat()
    
    @pytest.mark.asyncio
    async def test_get_subscription_status_premium_expired(self, subscription_service, mock_supabase_client):
        """Test getting subscription status for expired premium user"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        from datetime import timezone
        activated_at = datetime.now(timezone.utc) - timedelta(days=400)
        expires_at = datetime.now(timezone.utc) - timedelta(days=35)  # Expired 35 days ago
        
        # Mock database response
        mock_response = Mock()
        mock_response.data = [{
            "subscription_status": "premium",
            "subscription_activated_at": activated_at.isoformat(),
            "subscription_expires_at": expires_at.isoformat()
        }]
        
        mock_table = Mock()
        mock_table.select = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.get_subscription_status(user_id)
        
        # Assert
        assert result["plan"] == "premium"
        assert result["is_active"] is False  # Expired
    
    @pytest.mark.asyncio
    async def test_get_subscription_status_free_user(self, subscription_service, mock_supabase_client):
        """Test getting subscription status for free user"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        # Mock database response
        mock_response = Mock()
        mock_response.data = [{
            "subscription_status": "free",
            "subscription_activated_at": None,
            "subscription_expires_at": None
        }]
        
        mock_table = Mock()
        mock_table.select = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.get_subscription_status(user_id)
        
        # Assert
        assert result["plan"] == "free"
        assert result["is_active"] is False
        assert result["activated_at"] is None
        assert result["expires_at"] is None
    
    @pytest.mark.asyncio
    async def test_record_transaction_success(self, subscription_service, mock_supabase_client):
        """Test recording a successful transaction"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        transaction_id = "TXN_ABC123"
        payment_method = "bkash"
        amount = 999.00
        status = "success"
        metadata = {"mobile": "01712345678"}
        
        # Mock database response
        mock_response = Mock()
        mock_response.data = [{
            "id": "txn-uuid",
            "transaction_id": transaction_id,
            "user_id": user_id,
            "payment_method": payment_method,
            "amount": amount,
            "currency": "BDT",
            "status": status,
            "metadata": metadata,
            "created_at": datetime.utcnow().isoformat(),
            "verified_at": datetime.utcnow().isoformat()
        }]
        
        mock_table = Mock()
        mock_table.insert = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.record_transaction(
            user_id=user_id,
            transaction_id=transaction_id,
            payment_method=payment_method,
            amount=amount,
            status=status,
            metadata=metadata
        )
        
        # Assert
        assert result["transaction_id"] == transaction_id
        assert result["user_id"] == user_id
        assert result["payment_method"] == payment_method
        assert result["amount"] == amount
        assert result["status"] == status
        
        # Verify database was called correctly
        mock_supabase_client.table.assert_called_with("transactions")
        mock_table.insert.assert_called_once()
        insert_data = mock_table.insert.call_args[0][0]
        assert insert_data["transaction_id"] == transaction_id
        assert insert_data["status"] == status
        assert "verified_at" in insert_data  # Should have verified_at for success status
    
    @pytest.mark.asyncio
    async def test_record_transaction_pending(self, subscription_service, mock_supabase_client):
        """Test recording a pending transaction"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        transaction_id = "TXN_ABC123"
        payment_method = "credit_card"
        amount = 999.00
        status = "pending"
        
        # Mock database response
        mock_response = Mock()
        mock_response.data = [{
            "id": "txn-uuid",
            "transaction_id": transaction_id,
            "user_id": user_id,
            "payment_method": payment_method,
            "amount": amount,
            "currency": "BDT",
            "status": status,
            "metadata": {},
            "created_at": datetime.utcnow().isoformat(),
            "verified_at": None
        }]
        
        mock_table = Mock()
        mock_table.insert = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.record_transaction(
            user_id=user_id,
            transaction_id=transaction_id,
            payment_method=payment_method,
            amount=amount,
            status=status
        )
        
        # Assert
        assert result["status"] == "pending"
        
        # Verify verified_at is NOT set for pending transactions
        insert_data = mock_table.insert.call_args[0][0]
        assert "verified_at" not in insert_data
    
    @pytest.mark.asyncio
    async def test_record_transaction_invalid_payment_method(self, subscription_service, mock_supabase_client):
        """Test recording transaction with invalid payment method"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        transaction_id = "TXN_ABC123"
        invalid_method = "paypal"  # Not supported
        amount = 999.00
        status = "success"
        
        # Act & Assert
        with pytest.raises(ValueError, match="Invalid payment method"):
            await subscription_service.record_transaction(
                user_id=user_id,
                transaction_id=transaction_id,
                payment_method=invalid_method,
                amount=amount,
                status=status
            )
    
    @pytest.mark.asyncio
    async def test_record_transaction_invalid_status(self, subscription_service, mock_supabase_client):
        """Test recording transaction with invalid status"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        transaction_id = "TXN_ABC123"
        payment_method = "bkash"
        amount = 999.00
        invalid_status = "processing"  # Not supported
        
        # Act & Assert
        with pytest.raises(ValueError, match="Invalid status"):
            await subscription_service.record_transaction(
                user_id=user_id,
                transaction_id=transaction_id,
                payment_method=payment_method,
                amount=amount,
                status=invalid_status
            )
    
    @pytest.mark.asyncio
    async def test_record_transaction_negative_amount(self, subscription_service, mock_supabase_client):
        """Test recording transaction with negative amount"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        transaction_id = "TXN_ABC123"
        payment_method = "bkash"
        invalid_amount = -100.00
        status = "success"
        
        # Act & Assert
        with pytest.raises(ValueError, match="Amount must be positive"):
            await subscription_service.record_transaction(
                user_id=user_id,
                transaction_id=transaction_id,
                payment_method=payment_method,
                amount=invalid_amount,
                status=status
            )
    
    @pytest.mark.asyncio
    async def test_get_payment_history_success(self, subscription_service, mock_supabase_client):
        """Test retrieving payment history"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        # Mock database response with multiple transactions
        mock_response = Mock()
        mock_response.data = [
            {
                "transaction_id": "TXN_003",
                "payment_method": "bkash",
                "amount": 999.00,
                "currency": "BDT",
                "status": "success",
                "created_at": datetime.utcnow().isoformat(),
                "verified_at": datetime.utcnow().isoformat(),
                "metadata": {}
            },
            {
                "transaction_id": "TXN_002",
                "payment_method": "credit_card",
                "amount": 999.00,
                "currency": "BDT",
                "status": "failed",
                "created_at": (datetime.utcnow() - timedelta(days=1)).isoformat(),
                "verified_at": (datetime.utcnow() - timedelta(days=1)).isoformat(),
                "metadata": {}
            },
            {
                "transaction_id": "TXN_001",
                "payment_method": "debit_card",
                "amount": 999.00,
                "currency": "BDT",
                "status": "success",
                "created_at": (datetime.utcnow() - timedelta(days=30)).isoformat(),
                "verified_at": (datetime.utcnow() - timedelta(days=30)).isoformat(),
                "metadata": {}
            }
        ]
        
        mock_table = Mock()
        mock_table.select = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.order = Mock(return_value=mock_table)
        mock_table.range = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.get_payment_history(user_id, limit=50)
        
        # Assert
        assert len(result) == 3
        assert result[0]["transaction_id"] == "TXN_003"  # Most recent first
        assert result[1]["transaction_id"] == "TXN_002"
        assert result[2]["transaction_id"] == "TXN_001"
        
        # Verify database was called correctly
        mock_supabase_client.table.assert_called_with("transactions")
        mock_table.eq.assert_called_with("user_id", user_id)
        mock_table.order.assert_called_with("created_at", desc=True)
        mock_table.range.assert_called_with(0, 49)  # limit=50 means range 0-49
    
    @pytest.mark.asyncio
    async def test_get_payment_history_with_pagination(self, subscription_service, mock_supabase_client):
        """Test retrieving payment history with pagination"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        limit = 10
        offset = 20
        
        # Mock database response
        mock_response = Mock()
        mock_response.data = []
        
        mock_table = Mock()
        mock_table.select = Mock(return_value=mock_table)
        mock_table.eq = Mock(return_value=mock_table)
        mock_table.order = Mock(return_value=mock_table)
        mock_table.range = Mock(return_value=mock_table)
        mock_table.execute = Mock(return_value=mock_response)
        mock_supabase_client.table.return_value = mock_table
        
        # Act
        result = await subscription_service.get_payment_history(
            user_id, 
            limit=limit, 
            offset=offset
        )
        
        # Assert
        mock_table.range.assert_called_with(20, 29)  # offset=20, limit=10 means range 20-29
    
    @pytest.mark.asyncio
    async def test_get_payment_history_invalid_limit(self, subscription_service, mock_supabase_client):
        """Test retrieving payment history with invalid limit"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        invalid_limit = -5
        
        # Act & Assert
        with pytest.raises(ValueError, match="Limit must be positive"):
            await subscription_service.get_payment_history(user_id, limit=invalid_limit)
    
    @pytest.mark.asyncio
    async def test_get_payment_history_invalid_offset(self, subscription_service, mock_supabase_client):
        """Test retrieving payment history with invalid offset"""
        # Arrange
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        invalid_offset = -10
        
        # Act & Assert
        with pytest.raises(ValueError, match="Offset must be non-negative"):
            await subscription_service.get_payment_history(user_id, offset=invalid_offset)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
