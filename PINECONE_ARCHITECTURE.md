# Pinecone Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        ScholarMate System                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Flutter    │         │   FastAPI    │         │   Pinecone   │
│   Frontend   │◄───────►│   Backend    │◄───────►│    Cloud     │
│              │   API   │              │  Vector │              │
└──────────────┘         └──────────────┘  Search └──────────────┘
                                │
                                │
                         ┌──────▼──────┐
                         │   Supabase  │
                         │  PostgreSQL │
                         └─────────────┘
```

## Data Flow

### Indexing Flow

```
1. User uploads PDF
   │
   ├─► Frontend (Flutter)
   │   └─► POST /api/ingest/start
   │
   ├─► Backend (FastAPI)
   │   ├─► Download PDF from Google Drive
   │   ├─► Extract text (PyPDF)
   │   ├─► Chunk text (1000 chars)
   │   ├─► Generate embeddings (HuggingFace)
   │   │   └─► Model: all-MiniLM-L6-v2 (384 dims)
   │   └─► Store in Pinecone
   │       └─► Namespace: user_{user_id}
   │
   └─► Pinecone Cloud
       └─► Index: scholarmate
           └─► Vectors stored with metadata
```

### Query Flow

```
1. User asks question
   │
   ├─► Frontend (Flutter)
   │   └─► POST /api/ai/chat-rag
   │
   ├─► Backend (FastAPI)
   │   ├─► Generate query embedding (HuggingFace)
   │   ├─► Search Pinecone
   │   │   ├─► Namespace: user_{user_id}
   │   │   ├─► Filter: selected_file_ids (optional)
   │   │   └─► Top-k: 5 results
   │   ├─► Format context from results
   │   ├─► Call GROQ API
   │   │   └─► Generate answer with context
   │   └─► Extract citations
   │
   └─► Frontend (Flutter)
       └─► Display answer + citations
```

## Component Architecture

### Backend Services

```
backend/app/services/
│
├─► pinecone_service.py
│   ├─► Initialize Pinecone client
│   ├─► Create/manage index
│   ├─► Add documents to namespace
│   ├─► Query documents from namespace
│   └─► Delete documents by file
│
├─► rag_indexer.py
│   ├─► Extract text from PDF
│   ├─► Chunk text (RecursiveCharacterTextSplitter)
│   ├─► Generate embeddings (HuggingFace)
│   ├─► Store in Pinecone (via pinecone_service)
│   └─► Track job status (Supabase)
│
└─► rag_query_service.py
    ├─► Generate query embedding (HuggingFace)
    ├─► Search Pinecone (via pinecone_service)
    ├─► Format context
    ├─► Call GROQ API
    └─► Extract citations
```

## Data Storage

### Pinecone Structure

```
Pinecone Index: scholarmate
│
├─► Namespace: user_123abc
│   ├─► Vector: file1_chunk_0
│   │   ├─► Embedding: [0.1, 0.2, ..., 0.384]
│   │   └─► Metadata:
│   │       ├─► file_id: "file1"
│   │       ├─► file_name: "research.pdf"
│   │       ├─► page_number: 1
│   │       ├─► chunk_index: 0
│   │       └─► text: "This is the content..."
│   │
│   ├─► Vector: file1_chunk_1
│   └─► Vector: file1_chunk_2
│
├─► Namespace: user_456def
│   ├─► Vector: file2_chunk_0
│   └─► Vector: file2_chunk_1
│
└─► Namespace: user_789ghi
    └─► ...
```

### Supabase Structure

```
Supabase PostgreSQL
│
├─► users
│   ├─► id (UUID)
│   ├─► google_sub
│   ├─► email
│   └─► name
│
├─► files
│   ├─► id (UUID)
│   ├─► user_id (FK)
│   ├─► drive_file_id
│   ├─► name
│   └─► mime_type
│
└─► ingestion_jobs
    ├─► id (UUID)
    ├─► user_id (FK)
    ├─► file_id (FK)
    ├─► status
    ├─► progress_percent
    └─► metadata (JSONB)
```

## User Isolation

### Namespace-Based Isolation

```
┌─────────────────────────────────────────────────────────────┐
│                    Pinecone Index: scholarmate               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │ Namespace: user_123  │  │ Namespace: user_456  │        │
│  ├──────────────────────┤  ├──────────────────────┤        │
│  │ • file1_chunk_0      │  │ • file3_chunk_0      │        │
│  │ • file1_chunk_1      │  │ • file3_chunk_1      │        │
│  │ • file2_chunk_0      │  │ • file4_chunk_0      │        │
│  └──────────────────────┘  └──────────────────────┘        │
│                                                              │
│  ┌──────────────────────┐                                   │
│  │ Namespace: user_789  │                                   │
│  ├──────────────────────┤                                   │
│  │ • file5_chunk_0      │                                   │
│  │ • file5_chunk_1      │                                   │
│  └──────────────────────┘                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Benefits:
✅ Shared index (cost-efficient)
✅ Isolated data (secure)
✅ Fast queries (namespace filtering)
```

## Embedding Pipeline

### Text to Vector Conversion

```
Input Text:
"This is a research paper about machine learning."

    │
    ▼

Tokenization:
["This", "is", "a", "research", "paper", "about", "machine", "learning"]

    │
    ▼

HuggingFace Model:
sentence-transformers/all-MiniLM-L6-v2

    │
    ▼

Embedding Vector (384 dimensions):
[0.123, -0.456, 0.789, ..., 0.321]

    │
    ▼

Stored in Pinecone:
{
  "id": "file1_chunk_0",
  "values": [0.123, -0.456, ..., 0.321],
  "metadata": {
    "file_id": "file1",
    "text": "This is a research paper...",
    "page_number": 1
  }
}
```

## Query Processing

### Semantic Search Flow

```
User Question:
"What is machine learning?"

    │
    ▼

Generate Query Embedding:
[0.234, -0.567, 0.890, ..., 0.432]

    │
    ▼

Pinecone Cosine Search:
Compare with all vectors in namespace

    │
    ▼

Top-K Results (k=5):
1. file1_chunk_0 (score: 0.95)
2. file1_chunk_5 (score: 0.89)
3. file2_chunk_2 (score: 0.85)
4. file1_chunk_3 (score: 0.82)
5. file3_chunk_1 (score: 0.78)

    │
    ▼

Format Context:
"[Source 1: research.pdf, Page 1]
This is a research paper about machine learning...

[Source 2: research.pdf, Page 6]
Machine learning is a subset of AI..."

    │
    ▼

GROQ API:
Generate answer using context

    │
    ▼

Response:
{
  "message": "Machine learning is...",
  "citations": [
    {"file_id": "file1", "page": 1},
    {"file_id": "file1", "page": 6}
  ]
}
```

## Deployment Architecture

### Free Hosting Setup

```
┌─────────────────────────────────────────────────────────────┐
│                    Free Hosting Service                      │
│                  (Render/Railway/Fly.io)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │         FastAPI Backend Container              │         │
│  ├────────────────────────────────────────────────┤         │
│  │                                                 │         │
│  │  • No persistent disk needed ✅                │         │
│  │  • Ephemeral filesystem (OK)                   │         │
│  │  • Environment variables only                  │         │
│  │  • Model cache in /tmp (recreated on restart) │         │
│  │                                                 │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ HTTPS
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Pinecone   │  │   Supabase   │  │  GROQ API    │     │
│  │   (Vectors)  │  │  (Metadata)  │  │   (Chat)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

### Indexing Performance

```
PDF Document (10 pages)
│
├─► Text Extraction: ~1s/page = 10s
├─► Chunking: ~0.1s total
├─► Embedding Generation: ~0.5s/chunk × 100 chunks = 50s
└─► Pinecone Upload: ~0.2s/batch × 1 batch = 0.2s
    
Total: ~60s for 10-page PDF
```

### Query Performance

```
User Question
│
├─► Embedding Generation: ~0.1s
├─► Pinecone Search: ~0.1s
├─► GROQ API Call: ~1s
└─► Response Formatting: ~0.05s
    
Total: ~1.25s per query
```

## Scaling Characteristics

### Horizontal Scaling

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer                             │
└─────────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Backend 1   │ │  Backend 2   │ │  Backend 3   │
└──────────────┘ └──────────────┘ └──────────────┘
        │               │               │
        └───────────────┼───────────────┘
                        │
                        ▼
                ┌──────────────┐
                │   Pinecone   │
                │   (Shared)   │
                └──────────────┘

Benefits:
✅ Stateless backends
✅ Shared vector store
✅ Easy to scale
```

## Cost Structure

### Free Tier Breakdown

```
Pinecone Free Tier:
├─► Vectors: 100,000 max
├─► Storage: 2GB
├─► Indexes: 1 serverless
└─► Cost: $0/month

Capacity:
├─► PDFs: ~100 per user
├─► Chunks per PDF: ~1000
├─► Users: Multiple (shared index)
└─► Total: 100,000 vectors

Example:
├─► 10 users × 10 PDFs = 100 PDFs
├─► 100 PDFs × 1000 chunks = 100,000 vectors
└─► Perfect fit! ✅
```

## Security Model

### Data Isolation

```
Request Flow:
1. User authenticates (Google OAuth)
2. Backend validates user_id
3. Query scoped to user's namespace
4. Results filtered by user_id
5. No cross-user data leakage

Namespace Security:
├─► Each user: unique namespace
├─► Queries: namespace-scoped
├─► Isolation: enforced by Pinecone
└─► Metadata: includes user_id
```

## Monitoring & Observability

### Key Metrics

```
Application Metrics:
├─► Indexing jobs: pending/processing/completed/failed
├─► Query latency: p50, p95, p99
├─► Embedding generation time
└─► GROQ API usage

Pinecone Metrics:
├─► Vector count per namespace
├─► Query volume
├─► Storage usage
└─► Index health

Supabase Metrics:
├─► Job status distribution
├─► User activity
└─► File metadata
```

## Summary

This architecture provides:
- ✅ **Scalability**: Horizontal scaling with stateless backends
- ✅ **Reliability**: Cloud-based vector storage
- ✅ **Performance**: Fast semantic search (~100ms)
- ✅ **Cost**: Free tier sufficient for development
- ✅ **Security**: Namespace-based user isolation
- ✅ **Simplicity**: No persistent storage needed

Perfect for deploying ScholarMate to free hosting services! 🚀
