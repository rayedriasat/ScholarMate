"""Encryption service for sensitive data"""
import os
from cryptography.fernet import Fernet
from typing import Optional


class EncryptionService:
    """Service for encrypting and decrypting sensitive data"""
    
    def __init__(self):
        """Initialize encryption service with key from environment"""
        encryption_key = os.getenv("ENCRYPTION_KEY")
        if not encryption_key:
            raise ValueError("ENCRYPTION_KEY environment variable not set")
        
        self.cipher = Fernet(encryption_key.encode())
    
    def encrypt(self, plaintext: str) -> str:
        """
        Encrypt plaintext string
        
        Args:
            plaintext: String to encrypt
            
        Returns:
            Encrypted string (base64 encoded)
        """
        if not plaintext:
            return ""
        
        encrypted_bytes = self.cipher.encrypt(plaintext.encode())
        return encrypted_bytes.decode()
    
    def decrypt(self, ciphertext: str) -> str:
        """
        Decrypt ciphertext string
        
        Args:
            ciphertext: Encrypted string (base64 encoded)
            
        Returns:
            Decrypted plaintext string
        """
        if not ciphertext:
            return ""
        
        decrypted_bytes = self.cipher.decrypt(ciphertext.encode())
        return decrypted_bytes.decode()


# Singleton instance
_encryption_service: Optional[EncryptionService] = None


def get_encryption_service() -> EncryptionService:
    """Get or create encryption service singleton"""
    global _encryption_service
    if _encryption_service is None:
        _encryption_service = EncryptionService()
    return _encryption_service
