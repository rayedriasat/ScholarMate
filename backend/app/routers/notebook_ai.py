"""
Notebook AI Studio router for generating study materials.
"""

import logging
from fastapi import APIRouter, HTTPException, status
from typing import List, Optional
from pydantic import BaseModel

from app.services.rag_query_service import get_rag_query_service
from app.services.api_key_service import get_api_key_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/notebook-ai", tags=["Notebook AI"])


class GenerateQuizRequest(BaseModel):
    """Request for quiz generation."""
    user_id: str
    file_ids: List[str]
    num_questions: int = 5
    difficulty: str = "medium"
    preferred_provider: Optional[str] = None


class QuizQuestion(BaseModel):
    """Quiz question model."""
    question: str
    options: List[str]
    correct_index: int
    explanation: str


class GenerateQuizResponse(BaseModel):
    """Response for quiz generation."""
    questions: List[QuizQuestion]


class GenerateSummaryRequest(BaseModel):
    """Request for summary generation."""
    user_id: str
    file_ids: List[str]
    length: str = "medium"  # short, medium, long
    preferred_provider: Optional[str] = None


class GenerateSummaryResponse(BaseModel):
    """Response for summary generation."""
    summary: str
    key_points: List[str]


class GenerateMindMapRequest(BaseModel):
    """Request for mind map generation."""
    user_id: str
    file_ids: List[str]
    preferred_provider: Optional[str] = None


class MindMapNode(BaseModel):
    """Mind map node."""
    name: str
    children: Optional[List['MindMapNode']] = None


class GenerateMindMapResponse(BaseModel):
    """Response for mind map generation."""
    root: MindMapNode


class GenerateFlashcardsRequest(BaseModel):
    """Request for flashcard generation."""
    user_id: str
    file_ids: List[str]
    num_cards: int = 10
    preferred_provider: Optional[str] = None


class Flashcard(BaseModel):
    """Flashcard model."""
    front: str
    back: str


class GenerateFlashcardsResponse(BaseModel):
    """Response for flashcard generation."""
    flashcards: List[Flashcard]


@router.post("/generate-quiz", response_model=GenerateQuizResponse)
async def generate_quiz(request: GenerateQuizRequest) -> GenerateQuizResponse:
    """
    Generate quiz questions from selected files.
    
    Args:
        request: Quiz generation request
        
    Returns:
        Generated quiz questions
    """
    try:
        logger.info(f"Generating quiz for user {request.user_id} with {len(request.file_ids)} files")
        
        # Get API key service for provider selection
        api_key_service = get_api_key_service()
        provider = await api_key_service.get_active_provider(
            user_id=request.user_id,
            preferred_provider=request.preferred_provider
        )
        
        if not provider:
            raise ValueError("No AI provider available")
        
        # Create prompt for quiz generation
        prompt = f"""Based on the provided documents, generate {request.num_questions} multiple-choice quiz questions at {request.difficulty} difficulty level.

For each question, provide:
1. The question text
2. Four answer options (A, B, C, D)
3. The index of the correct answer (0-3)
4. A brief explanation of why the answer is correct

Format your response as a JSON array of questions with this structure:
[
  {{
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correct_index": 0,
    "explanation": "Explanation here"
  }}
]

Make the questions challenging but fair, covering key concepts from the material."""

        # Get RAG service to retrieve context
        rag_service = get_rag_query_service()
        
        # Resolve user ID to UUID (handles Google sub IDs)
        resolved_user_id = await rag_service._get_or_create_user_uuid(request.user_id)
        
        # Retrieve context from files
        logger.info(f"🔍 Retrieving context with file_ids: {request.file_ids}")
        context_chunks = await rag_service.retrieve_context(
            question=prompt,
            user_id=resolved_user_id,
            selected_file_ids=request.file_ids,
            top_k=10
        )
        
        logger.info(f"🔍 Retrieved {len(context_chunks) if context_chunks else 0} chunks")
        
        if not context_chunks:
            raise ValueError(f"No content found in selected files. File IDs: {request.file_ids}")
        
        # Format context
        context_text = rag_service._format_context(context_chunks)
        
        # Generate quiz using AI provider
        messages = [
            {
                "role": "system",
                "content": "You are an expert educator creating quiz questions. Always respond with valid JSON."
            },
            {
                "role": "user",
                "content": f"Context from documents:\n{context_text}\n\n{prompt}"
            }
        ]
        
        response = await provider.chat(
            messages=messages,
            temperature=0.7,
            max_tokens=2000
        )
        
        # Parse response
        import json
        content = response['content']
        
        # Extract JSON from response (handle markdown code blocks)
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].split('```')[0].strip()
        
        questions_data = json.loads(content)
        
        # Convert to Pydantic models
        questions = [QuizQuestion(**q) for q in questions_data[:request.num_questions]]
        
        # Log usage
        await api_key_service.log_usage(
            user_id=request.user_id,
            provider=provider.get_provider_name(),
            endpoint="generate_quiz",
            request_tokens=response.get('usage', {}).get('prompt_tokens', 0),
            response_tokens=response.get('usage', {}).get('completion_tokens', 0),
            status="success"
        )
        
        logger.info(f"Generated {len(questions)} quiz questions")
        return GenerateQuizResponse(questions=questions)
        
    except Exception as e:
        logger.error(f"Quiz generation failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate quiz: {str(e)}"
        )


@router.post("/generate-summary", response_model=GenerateSummaryResponse)
async def generate_summary(request: GenerateSummaryRequest) -> GenerateSummaryResponse:
    """
    Generate summary from selected files.
    
    Args:
        request: Summary generation request
        
    Returns:
        Generated summary
    """
    try:
        logger.info(f"Generating summary for user {request.user_id}")
        
        api_key_service = get_api_key_service()
        provider = await api_key_service.get_active_provider(
            user_id=request.user_id,
            preferred_provider=request.preferred_provider
        )
        
        if not provider:
            raise ValueError("No AI provider available")
        
        # Length specifications
        length_specs = {
            "short": "a brief 2-3 paragraph summary",
            "medium": "a comprehensive 4-6 paragraph summary",
            "long": "a detailed multi-section summary"
        }
        
        prompt = f"""Create {length_specs.get(request.length, length_specs['medium'])} of the provided documents.

Include:
1. Main themes and concepts
2. Key findings or arguments
3. Important details and examples

Also provide 5-7 key bullet points highlighting the most important takeaways.

Format your response as JSON:
{{
  "summary": "Full summary text here...",
  "key_points": ["Point 1", "Point 2", ...]
}}"""

        rag_service = get_rag_query_service()
        
        # Resolve user ID to UUID
        resolved_user_id = await rag_service._get_or_create_user_uuid(request.user_id)
        
        logger.info(f"🔍 Retrieving context with file_ids: {request.file_ids}")
        context_chunks = await rag_service.retrieve_context(
            question=prompt,
            user_id=resolved_user_id,
            selected_file_ids=request.file_ids,
            top_k=15
        )
        
        logger.info(f"🔍 Retrieved {len(context_chunks) if context_chunks else 0} chunks")
        
        if not context_chunks:
            raise ValueError(f"No content found in selected files. File IDs: {request.file_ids}")
        
        context_text = rag_service._format_context(context_chunks)
        
        messages = [
            {
                "role": "system",
                "content": "You are an expert at creating clear, concise summaries. Always respond with valid JSON."
            },
            {
                "role": "user",
                "content": f"Context from documents:\n{context_text}\n\n{prompt}"
            }
        ]
        
        response = await provider.chat(
            messages=messages,
            temperature=0.5,
            max_tokens=2000
        )
        
        # Parse response
        import json
        content = response['content']
        
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].split('```')[0].strip()
        
        summary_data = json.loads(content)
        
        await api_key_service.log_usage(
            user_id=request.user_id,
            provider=provider.get_provider_name(),
            endpoint="generate_summary",
            request_tokens=response.get('usage', {}).get('prompt_tokens', 0),
            response_tokens=response.get('usage', {}).get('completion_tokens', 0),
            status="success"
        )
        
        return GenerateSummaryResponse(**summary_data)
        
    except Exception as e:
        logger.error(f"Summary generation failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate summary: {str(e)}"
        )


@router.post("/generate-flashcards", response_model=GenerateFlashcardsResponse)
async def generate_flashcards(request: GenerateFlashcardsRequest) -> GenerateFlashcardsResponse:
    """
    Generate flashcards from selected files.
    
    Args:
        request: Flashcard generation request
        
    Returns:
        Generated flashcards
    """
    try:
        logger.info(f"Generating flashcards for user {request.user_id}")
        
        api_key_service = get_api_key_service()
        provider = await api_key_service.get_active_provider(
            user_id=request.user_id,
            preferred_provider=request.preferred_provider
        )
        
        if not provider:
            raise ValueError("No AI provider available")
        
        prompt = f"""Create {request.num_cards} flashcards from the provided documents for study and review.

Each flashcard should have:
- Front: A question, term, or concept
- Back: The answer, definition, or explanation

Focus on key concepts, important terms, and critical information.

Format your response as JSON:
{{
  "flashcards": [
    {{"front": "Question or term", "back": "Answer or definition"}},
    ...
  ]
}}"""

        rag_service = get_rag_query_service()
        
        # Resolve user ID to UUID
        resolved_user_id = await rag_service._get_or_create_user_uuid(request.user_id)
        
        logger.info(f"🔍 Retrieving context with file_ids: {request.file_ids}")
        context_chunks = await rag_service.retrieve_context(
            question=prompt,
            user_id=resolved_user_id,
            selected_file_ids=request.file_ids,
            top_k=12
        )
        
        logger.info(f"🔍 Retrieved {len(context_chunks) if context_chunks else 0} chunks")
        
        if not context_chunks:
            raise ValueError(f"No content found in selected files. File IDs: {request.file_ids}")
        
        context_text = rag_service._format_context(context_chunks)
        
        messages = [
            {
                "role": "system",
                "content": "You are an expert at creating effective study flashcards. Always respond with valid JSON."
            },
            {
                "role": "user",
                "content": f"Context from documents:\n{context_text}\n\n{prompt}"
            }
        ]
        
        response = await provider.chat(
            messages=messages,
            temperature=0.6,
            max_tokens=2000
        )
        
        # Parse response
        import json
        content = response['content']
        
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].split('```')[0].strip()
        
        flashcards_data = json.loads(content)
        
        await api_key_service.log_usage(
            user_id=request.user_id,
            provider=provider.get_provider_name(),
            endpoint="generate_flashcards",
            request_tokens=response.get('usage', {}).get('prompt_tokens', 0),
            response_tokens=response.get('usage', {}).get('completion_tokens', 0),
            status="success"
        )
        
        flashcards = [Flashcard(**fc) for fc in flashcards_data['flashcards'][:request.num_cards]]
        
        return GenerateFlashcardsResponse(flashcards=flashcards)
        
    except Exception as e:
        logger.error(f"Flashcard generation failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate flashcards: {str(e)}"
        )


class GenerateAudioRequest(BaseModel):
    """Request for audio review generation."""
    user_id: str
    file_ids: List[str]
    preferred_provider: Optional[str] = None


class AudioSegment(BaseModel):
    """Single audio segment in the conversation."""
    speaker: str  # "Host 1" or "Host 2"
    text: str


class GenerateAudioResponse(BaseModel):
    """Response for audio review generation."""
    segments: List[AudioSegment]
    title: str


@router.post("/generate-audio", response_model=GenerateAudioResponse)
async def generate_audio(request: GenerateAudioRequest) -> GenerateAudioResponse:
    """
    Generate conversational audio review script from selected files.
    
    Args:
        request: Audio generation request
        
    Returns:
        Generated conversation script
    """
    try:
        logger.info(f"Generating audio review for user {request.user_id} with {len(request.file_ids)} files")
        
        # Get API key service for provider selection
        api_key_service = get_api_key_service()
        provider = await api_key_service.get_active_provider(
            user_id=request.user_id,
            preferred_provider=request.preferred_provider
        )
        
        if not provider:
            raise ValueError("No AI provider available")
        
        # Create prompt for conversational script generation
        prompt = """Based on the provided documents, create an engaging podcast-style conversation between two AI hosts discussing the content.

Host 1 (Alex) should be curious and ask questions.
Host 2 (Sam) should provide explanations and insights.

Make the conversation:
- Natural and engaging (like a real podcast)
- Cover key concepts and main ideas
- Use simple language and analogies
- Include transitions between topics
- About 8-12 exchanges total

Format your response as a JSON object with this structure:
{
  "title": "Brief title for the audio review",
  "segments": [
    {
      "speaker": "Host 1",
      "text": "Hey Sam, I've been reading about..."
    },
    {
      "speaker": "Host 2", 
      "text": "Great question Alex! Let me explain..."
    }
  ]
}

Make it informative but conversational. Aim for a 3-5 minute discussion when read aloud."""

        # Get RAG service to retrieve context
        rag_service = get_rag_query_service()
        
        # Resolve user ID to UUID
        resolved_user_id = await rag_service._get_or_create_user_uuid(request.user_id)
        
        # Retrieve context from files
        logger.info(f"🔍 Retrieving context with file_ids: {request.file_ids}")
        context_chunks = await rag_service.retrieve_context(
            question=prompt,
            user_id=resolved_user_id,
            selected_file_ids=request.file_ids,
            top_k=15
        )
        
        if not context_chunks:
            raise ValueError("No content found in the selected files")
        
        # Format context using RAG service method
        context_text = rag_service._format_context(context_chunks)
        
        logger.info(f"📚 Retrieved {len(context_chunks)} context chunks")
        
        # Generate conversational script using chat interface
        messages = [
            {
                "role": "system",
                "content": "You are an expert at creating engaging podcast-style conversations. Always respond with valid JSON."
            },
            {
                "role": "user",
                "content": f"Context from documents:\n{context_text}\n\n{prompt}"
            }
        ]
        
        response = await provider.chat(
            messages=messages,
            max_tokens=2000,
            temperature=0.8  # Higher temperature for more natural conversation
        )
        
        # Parse response
        import json
        content = response['content']
        
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].split('```')[0].strip()
        
        audio_data = json.loads(content)
        
        await api_key_service.log_usage(
            user_id=request.user_id,
            provider=provider.get_provider_name(),
            endpoint="generate_audio",
            request_tokens=response.get('usage', {}).get('prompt_tokens', 0),
            response_tokens=response.get('usage', {}).get('completion_tokens', 0),
            status="success"
        )
        
        segments = [AudioSegment(**seg) for seg in audio_data['segments']]
        title = audio_data.get('title', 'Audio Review')
        
        logger.info(f"✅ Generated {len(segments)} audio segments")
        
        return GenerateAudioResponse(segments=segments, title=title)
        
    except Exception as e:
        logger.error(f"Audio generation failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate audio review: {str(e)}"
        )


# Enable forward references for nested models
MindMapNode.model_rebuild()
