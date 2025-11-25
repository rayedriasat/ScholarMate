"""Service for document extraction using OCR + AI"""
import json
import logging
from typing import Dict, Any, List, Optional
from uuid import uuid4
from datetime import datetime
from .groq_service import get_groq_service
from .supabase_service import get_supabase_service

logger = logging.getLogger(__name__)


class ExtractionService:
    """Service for AI-powered document extraction"""
    
    def __init__(self):
        self.groq = get_groq_service()
        self.supabase = get_supabase_service()
    
    async def extract_document_data(self, ocr_text: str) -> Dict[str, Any]:
        """
        Extract structured data from OCR text using AI
        
        Args:
            ocr_text: Text extracted from document via OCR
            
        Returns:
            Dict with document_type, extracted_fields, summary, and tags
        """
        try:
            logger.info(f"Extracting data from OCR text ({len(ocr_text)} characters)")
            
            # Create AI prompt for extraction
            prompt = self._create_extraction_prompt(ocr_text)
            
            # Call AI model
            messages = [
                {"role": "system", "content": "You are an expert document analyzer. Extract structured data from documents accurately and concisely."},
                {"role": "user", "content": prompt}
            ]
            
            response = await self.groq.chat(
                messages=messages,
                temperature=0.3,  # Lower temperature for more consistent extraction
                max_tokens=2000
            )
            
            # Parse AI response
            extracted_data = self._parse_ai_response(response["content"])
            
            logger.info(f"Successfully extracted data: type={extracted_data['document_type']}")
            return extracted_data
            
        except Exception as e:
            logger.error(f"Error extracting document data: {e}")
            raise
    
    def _create_extraction_prompt(self, ocr_text: str) -> str:
        """Create prompt for AI extraction"""
        return f"""Analyze the following OCR-extracted text from a document and extract structured information.

OCR Text:
{ocr_text}

Please provide a JSON response with the following structure:
{{
    "document_type": "One of: Hospital, Appointment, ID Card, Bill, Prescription, Receipt, Invoice, Medical Report, Lab Report, Insurance, License, Certificate, or Other",
    "extracted_fields": {{
        "key1": "value1",
        "key2": "value2"
        // Extract ALL relevant fields like: name, date, time, id_number, amount, doctor_name, hospital_name, patient_id, appointment_date, prescription_details, etc.
    }},
    "summary": "A concise 1-2 sentence summary of the document",
    "tags": ["tag1", "tag2", "tag3"]  // Auto-generate 2-5 relevant tags
}}

IMPORTANT RULES:
1. Only extract information that is clearly visible in the text
2. Do NOT guess or infer information that isn't present
3. Use consistent key names (snake_case)
4. For dates, use ISO format (YYYY-MM-DD) if possible
5. For amounts, include currency if mentioned
6. Extract ALL visible fields, not just common ones
7. Tags should be descriptive and relevant (e.g., "medical", "urgent", "financial")
8. Summary should capture the main purpose/content of the document

Return ONLY valid JSON, no additional text."""
    
    def _parse_ai_response(self, ai_response: str) -> Dict[str, Any]:
        """Parse AI response into structured data"""
        try:
            # Try to extract JSON from response
            # Sometimes AI adds markdown code blocks
            response_text = ai_response.strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith("```json"):
                response_text = response_text[7:]
            elif response_text.startswith("```"):
                response_text = response_text[3:]
            
            if response_text.endswith("```"):
                response_text = response_text[:-3]
            
            response_text = response_text.strip()
            
            # Parse JSON
            data = json.loads(response_text)
            
            # Validate required fields
            required_fields = ["document_type", "extracted_fields", "summary", "tags"]
            for field in required_fields:
                if field not in data:
                    raise ValueError(f"Missing required field: {field}")
            
            # Ensure tags is a list
            if not isinstance(data["tags"], list):
                data["tags"] = []
            
            # Ensure extracted_fields is a dict
            if not isinstance(data["extracted_fields"], dict):
                data["extracted_fields"] = {}
            
            return data
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI response as JSON: {e}")
            logger.error(f"Response was: {ai_response}")
            # Return fallback structure
            return {
                "document_type": "Other",
                "extracted_fields": {"raw_text": ai_response[:500]},
                "summary": "Failed to parse document structure",
                "tags": ["unprocessed"]
            }
        except Exception as e:
            logger.error(f"Error parsing AI response: {e}")
            raise
    
    async def create_extracted_document(
        self,
        user_id: str,
        document_type: str,
        extracted_data: Dict[str, Any],
        summary: str,
        image_url: Optional[str],
        tags: List[str]
    ) -> Dict[str, Any]:
        """
        Save extracted document to database
        
        Args:
            user_id: User ID
            document_type: Type of document
            extracted_data: Extracted key-value pairs
            summary: Document summary
            image_url: URL/ID of original image
            tags: List of tags
            
        Returns:
            Created document record
        """
        try:
            doc_data = {
                "id": str(uuid4()),
                "user_id": user_id,
                "document_type": document_type,
                "extracted_data": extracted_data,
                "summary": summary,
                "image_url": image_url,
                "tags": tags,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat()
            }
            
            response = self.supabase.client.table("extracted_documents").insert(doc_data).execute()
            
            if response.data:
                logger.info(f"Created extracted document {doc_data['id']}")
                return response.data[0]
            else:
                raise Exception("Failed to create extracted document")
                
        except Exception as e:
            logger.error(f"Error creating extracted document: {e}")
            raise
    
    async def get_extracted_documents(
        self,
        user_id: str,
        document_type: Optional[str] = None,
        tags: Optional[List[str]] = None,
        search_query: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get extracted documents for a user with optional filters"""
        try:
            query = self.supabase.client.table("extracted_documents").select("*").eq("user_id", user_id)
            
            if document_type:
                query = query.eq("document_type", document_type)
            
            # Note: Supabase filtering for JSON arrays and text search would need additional logic
            # For now, we'll fetch and filter in Python
            
            response = query.order("created_at", desc=True).execute()
            documents = response.data
            
            # Apply additional filters
            if tags:
                documents = [doc for doc in documents if any(tag in doc.get("tags", []) for tag in tags)]
            
            if search_query:
                search_lower = search_query.lower()
                documents = [
                    doc for doc in documents
                    if search_lower in doc.get("summary", "").lower()
                    or search_lower in doc.get("document_type", "").lower()
                    or any(search_lower in str(v).lower() for v in doc.get("extracted_data", {}).values())
                ]
            
            logger.info(f"Retrieved {len(documents)} extracted documents for user {user_id}")
            return documents
            
        except Exception as e:
            logger.error(f"Error getting extracted documents: {e}")
            raise
    
    async def get_extracted_document(self, user_id: str, document_id: str) -> Optional[Dict[str, Any]]:
        """Get a single extracted document by ID"""
        try:
            response = self.supabase.client.table("extracted_documents").select("*").eq("id", document_id).eq("user_id", user_id).execute()
            
            if response.data:
                return response.data[0]
            return None
            
        except Exception as e:
            logger.error(f"Error getting extracted document {document_id}: {e}")
            raise
    
    async def update_extracted_document(
        self,
        user_id: str,
        document_id: str,
        updates: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Update an extracted document"""
        try:
            # Verify ownership
            existing = await self.get_extracted_document(user_id, document_id)
            if not existing:
                raise Exception("Document not found or access denied")
            
            # Add updated timestamp
            updates["updated_at"] = datetime.utcnow().isoformat()
            
            response = self.supabase.client.table("extracted_documents").update(updates).eq("id", document_id).execute()
            
            if response.data:
                logger.info(f"Updated extracted document {document_id}")
                return response.data[0]
            else:
                raise Exception("Failed to update document")
                
        except Exception as e:
            logger.error(f"Error updating extracted document {document_id}: {e}")
            raise
    
    async def delete_extracted_document(self, user_id: str, document_id: str) -> bool:
        """Delete an extracted document"""
        try:
            # Verify ownership
            existing = await self.get_extracted_document(user_id, document_id)
            if not existing:
                raise Exception("Document not found or access denied")
            
            self.supabase.client.table("extracted_documents").delete().eq("id", document_id).execute()
            
            logger.info(f"Deleted extracted document {document_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting extracted document {document_id}: {e}")
            raise


# Singleton instance
_extraction_service: Optional[ExtractionService] = None


def get_extraction_service() -> ExtractionService:
    """Get or create extraction service singleton"""
    global _extraction_service
    if _extraction_service is None:
        _extraction_service = ExtractionService()
    return _extraction_service
