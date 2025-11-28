"""
Payment Gateway Factory

This module provides a factory function for creating payment gateway instances
based on environment configuration. It enables seamless switching between
different payment gateway implementations without modifying application code.

The factory pattern allows:
- Easy testing with mock gateway in development
- Simple migration to production gateways (SSLCommerz, bKash)
- Configuration-driven gateway selection
- Centralized gateway instantiation logic

Usage:
    from app.services.payment_gateway_factory import get_payment_gateway
    
    gateway = get_payment_gateway()
    result = await gateway.initialize_payment(...)
"""

from .payment_gateway_interface import PaymentGatewayInterface
from .mock_payment_gateway import MockPaymentGateway
import os

# TODO: Import real payment gateway implementations when available
# from .sslcommerz_gateway import SSLCommerzGateway
# from .bkash_gateway import BkashOfficialGateway


def get_payment_gateway() -> PaymentGatewayInterface:
    """
    Factory function to get the configured payment gateway implementation.
    
    Returns the appropriate payment gateway based on the PAYMENT_GATEWAY_TYPE
    environment variable. This allows switching between mock and real gateways
    without code changes.
    
    Environment Variables:
        PAYMENT_GATEWAY_TYPE: Gateway type to use
            - "mock" (default): MockPaymentGateway for demonstration
            - "sslcommerz": SSLCommerz payment gateway (TODO: implement)
            - "bkash": bKash Official API gateway (TODO: implement)
    
    Returns:
        PaymentGatewayInterface: Configured payment gateway instance
    
    Raises:
        ValueError: If PAYMENT_GATEWAY_TYPE is not recognized
    
    Example:
        >>> # In .env file: PAYMENT_GATEWAY_TYPE=mock
        >>> gateway = get_payment_gateway()
        >>> isinstance(gateway, MockPaymentGateway)
        True
    
    TODO: Implement real payment gateway cases
    
    When SSLCommerz integration is ready:
    1. Implement SSLCommerzGateway class in sslcommerz_gateway.py
    2. Add required environment variables:
       - SSLCOMMERZ_STORE_ID
       - SSLCOMMERZ_STORE_PASSWORD
       - SSLCOMMERZ_API_URL
    3. Uncomment the SSLCommerz case below
    
    When bKash Official API integration is ready:
    1. Implement BkashOfficialGateway class in bkash_gateway.py
    2. Add required environment variables:
       - BKASH_APP_KEY
       - BKASH_APP_SECRET
       - BKASH_USERNAME
       - BKASH_PASSWORD
       - BKASH_API_URL
    3. Uncomment the bKash case below
    """
    gateway_type = os.getenv("PAYMENT_GATEWAY_TYPE", "mock").lower()
    
    if gateway_type == "mock":
        # Return mock gateway for demonstration and testing
        return MockPaymentGateway()
    
    # TODO: Add SSLCommerz gateway case
    # elif gateway_type == "sslcommerz":
    #     # Validate required environment variables
    #     store_id = os.getenv("SSLCOMMERZ_STORE_ID")
    #     store_password = os.getenv("SSLCOMMERZ_STORE_PASSWORD")
    #     api_url = os.getenv("SSLCOMMERZ_API_URL")
    #     
    #     if not all([store_id, store_password, api_url]):
    #         raise ValueError(
    #             "SSLCommerz gateway requires: SSLCOMMERZ_STORE_ID, "
    #             "SSLCOMMERZ_STORE_PASSWORD, SSLCOMMERZ_API_URL"
    #         )
    #     
    #     return SSLCommerzGateway(
    #         store_id=store_id,
    #         store_password=store_password,
    #         api_url=api_url
    #     )
    
    # TODO: Add bKash Official API gateway case
    # elif gateway_type == "bkash":
    #     # Validate required environment variables
    #     app_key = os.getenv("BKASH_APP_KEY")
    #     app_secret = os.getenv("BKASH_APP_SECRET")
    #     username = os.getenv("BKASH_USERNAME")
    #     password = os.getenv("BKASH_PASSWORD")
    #     api_url = os.getenv("BKASH_API_URL")
    #     
    #     if not all([app_key, app_secret, username, password, api_url]):
    #         raise ValueError(
    #             "bKash gateway requires: BKASH_APP_KEY, BKASH_APP_SECRET, "
    #             "BKASH_USERNAME, BKASH_PASSWORD, BKASH_API_URL"
    #         )
    #     
    #     return BkashOfficialGateway(
    #         app_key=app_key,
    #         app_secret=app_secret,
    #         username=username,
    #         password=password,
    #         api_url=api_url
    #     )
    
    else:
        raise ValueError(
            f"Unknown payment gateway type: '{gateway_type}'. "
            f"Supported types: mock, sslcommerz (TODO), bkash (TODO)"
        )
