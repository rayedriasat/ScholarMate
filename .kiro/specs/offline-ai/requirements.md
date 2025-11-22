# Requirements Document: Offline AI with Local LLM and Embeddings

## Introduction

This feature extends ScholarMate's AI capabilities to work completely offline by introducing local LLM inference and embedding generation on user devices. The system will maintain the existing cloud-based RAG architecture while adding offline-first AI capabilities that sync across devices when online. This enables users to continue AI-powered research workflows without internet connectivity while preserving their ability to switch devices seamlessly.

## Glossary

- **LLM**: Large Language Model - AI model that generates human-like text responses
- **Embedding**: Vector representation of text used for semantic search
- **RAG**: Retrieval-Augmented Generation - AI technique combining document search with text generation
- **ONNX**: Open Neural Network Exchange - cross-platform ML model format
- **WebGPU**: Browser API for GPU-accelerated computing
- **Quantization**: Model compression technique reducing size and memory requirements
- **Drift**: SQLite-based local database used by ScholarMate for offline-first storage
- **Pinecone**: Cloud vector database for storing embeddings
- **Supabase**: Cloud database for metadata and sync
- **PWA**: Progressive Web App - web application with offline capabilities
- **WASM**: WebAssembly - binary instruction format for web browsers
- **System**: ScholarMate application (frontend and backend components)

## Requirements

### Requirement 1: Local Embedding Generation

**User Story:** As a researcher, I want embeddings to be generated locally on my device, so that I can index documents without internet connectivity and without relying on external API costs.

#### Acceptance Criteria

1. WHEN the System generates embeddings for document chunks THEN the System SHALL use on-device embedding models
2. WHEN the System runs on Android or Windows THEN the System SHALL use ONNX Runtime for embedding generation
3. WHEN the System runs on Web (PWA) THEN the System SHALL use Transformers.js with WASM backend for embedding generation
4. WHEN the System generates embeddings THEN the System SHALL produce 384-dimensional vectors compatible with existing Pinecone indices
5. WHEN the System generates embeddings offline THEN the System SHALL queue embeddings for sync to Pinecone when online
6. WHEN the System is online THEN the System SHALL sync queued embeddings to Pinecone automatically
7. WHEN embedding generation fails THEN the System SHALL provide clear error messages and fallback options

### Requirement 2: Local LLM Inference

**User Story:** As a researcher, I want to run AI chat completely offline on my device, so that I can continue my research workflow without internet access and maintain complete privacy.

#### Acceptance Criteria

1. WHEN the System performs AI chat inference THEN the System SHALL support both local and cloud-based LLM execution
2. WHEN the System runs on Android or Windows THEN the System SHALL use llama.cpp via flutter_llama_cpp for local inference
3. WHEN the System runs on Web (PWA) THEN the System SHALL use WebLLM with WebGPU acceleration for local inference
4. WHEN the System loads a local LLM THEN the System SHALL use quantized models (Q4 or Q8 format) to minimize memory usage
5. WHEN the System is offline THEN the System SHALL automatically use local LLM for chat responses
6. WHEN the System is online THEN the System SHALL allow users to choose between local and cloud LLM providers
7. WHEN local LLM inference fails THEN the System SHALL provide clear error messages and suggest cloud fallback if online

### Requirement 3: Offline RAG Query Pipeline

**User Story:** As a researcher, I want to perform semantic search and get AI-generated answers from my documents while offline, so that I can continue my research without internet connectivity.

#### Acceptance Criteria

1. WHEN the System performs RAG queries offline THEN the System SHALL use local embeddings and local vector search
2. WHEN the System performs semantic search offline THEN the System SHALL search cached embeddings stored in Drift database
3. WHEN the System retrieves relevant chunks offline THEN the System SHALL use cosine similarity for ranking
4. WHEN the System generates answers offline THEN the System SHALL use local LLM with retrieved context
5. WHEN the System performs RAG queries online THEN the System SHALL use Pinecone for vector search and user-selected LLM provider
6. WHEN the System switches between offline and online modes THEN the System SHALL maintain consistent RAG response quality
7. WHEN offline RAG query fails THEN the System SHALL provide actionable error messages

### Requirement 4: Cross-Platform Model Support

**User Story:** As a developer, I want the System to use appropriate ML frameworks for each platform, so that users get optimal performance regardless of their device.

#### Acceptance Criteria

1. WHEN the System runs on Android THEN the System SHALL use ONNX Runtime for embeddings and llama.cpp for LLM
2. WHEN the System runs on Windows THEN the System SHALL use ONNX Runtime for embeddings and llama.cpp for LLM
3. WHEN the System runs on Web THEN the System SHALL use Transformers.js for embeddings and WebLLM for LLM
4. WHEN the System initializes ML models THEN the System SHALL detect platform capabilities and select appropriate backend
5. WHEN the System runs on Web THEN the System SHALL use WebGPU when available and fallback to WASM
6. WHEN the System loads models THEN the System SHALL show progress indicators for model downloads
7. WHEN platform lacks required capabilities THEN the System SHALL gracefully degrade to cloud-only mode

### Requirement 5: Model Management and Storage

**User Story:** As a user, I want to download and manage AI models on my device, so that I can control storage usage and model selection.

#### Acceptance Criteria

1. WHEN the System first runs THEN the System SHALL prompt users to download required models
2. WHEN the System downloads models THEN the System SHALL show download progress with size and speed information
3. WHEN the System stores models THEN the System SHALL use platform-appropriate storage locations
4. WHEN the System manages models THEN the System SHALL allow users to delete models to free storage space
5. WHEN the System selects models THEN the System SHALL offer multiple model sizes (1B, 3B, 7B parameters)
6. WHEN the System updates models THEN the System SHALL preserve user preferences and cached data
7. WHEN storage is insufficient THEN the System SHALL warn users before downloading models

### Requirement 6: Embedding Sync and Conflict Resolution

**User Story:** As a researcher using multiple devices, I want my document embeddings to sync across devices, so that I can seamlessly switch between devices without re-indexing.

#### Acceptance Criteria

1. WHEN the System generates embeddings offline THEN the System SHALL store embeddings in local Drift database
2. WHEN the System comes online THEN the System SHALL sync local embeddings to Pinecone automatically
3. WHEN the System syncs embeddings THEN the System SHALL use batch uploads to minimize API calls
4. WHEN the System detects embedding conflicts THEN the System SHALL use last-write-wins strategy
5. WHEN the System syncs embeddings THEN the System SHALL maintain embedding metadata (file_id, chunk_index, page_number)
6. WHEN the System completes sync THEN the System SHALL update sync status indicators
7. WHEN sync fails THEN the System SHALL retry with exponential backoff

### Requirement 7: Chat History Sync

**User Story:** As a researcher using multiple devices, I want my AI chat history to sync across devices, so that I can continue conversations from any device.

#### Acceptance Criteria

1. WHEN the System saves chat messages THEN the System SHALL store messages in local Drift database
2. WHEN the System comes online THEN the System SHALL sync chat history to Supabase automatically
3. WHEN the System syncs chat history THEN the System SHALL include message content, timestamps, and citations
4. WHEN the System detects chat conflicts THEN the System SHALL merge conversations by timestamp
5. WHEN the System loads chat history THEN the System SHALL fetch from Supabase when online and Drift when offline
6. WHEN the System displays chat history THEN the System SHALL indicate which messages were generated locally vs cloud
7. WHEN sync fails THEN the System SHALL preserve local chat history and retry later

### Requirement 8: Performance and Resource Management

**User Story:** As a user, I want the System to manage device resources efficiently, so that AI features don't drain battery or consume excessive memory.

#### Acceptance Criteria

1. WHEN the System loads models THEN the System SHALL use lazy loading to minimize initial memory footprint
2. WHEN the System is idle THEN the System SHALL unload models after configurable timeout period
3. WHEN the System detects low memory THEN the System SHALL automatically unload models and warn users
4. WHEN the System performs inference THEN the System SHALL use hardware acceleration when available
5. WHEN the System runs on battery power THEN the System SHALL offer power-saving mode with reduced model sizes
6. WHEN the System processes large documents THEN the System SHALL use streaming and batching to prevent memory spikes
7. WHEN the System monitors resources THEN the System SHALL provide memory and battery usage statistics

### Requirement 9: Model Selection and Configuration

**User Story:** As a user, I want to configure which AI models to use, so that I can balance performance, quality, and resource usage based on my needs.

#### Acceptance Criteria

1. WHEN the System provides model selection THEN the System SHALL offer embedding models (MiniLM-L6, MiniLM-L12, BGE-small)
2. WHEN the System provides model selection THEN the System SHALL offer LLM models (Phi-3-mini, Llama-3.2-1B, Llama-3.2-3B, Qwen2-1.5B)
3. WHEN the System displays model options THEN the System SHALL show model size, memory requirements, and quality ratings
4. WHEN the System changes models THEN the System SHALL re-index documents if embedding dimensions change
5. WHEN the System configures models THEN the System SHALL persist user preferences across sessions
6. WHEN the System recommends models THEN the System SHALL suggest models based on device capabilities
7. WHEN model configuration changes THEN the System SHALL warn users about storage and re-indexing implications

### Requirement 10: Offline Mode Indicators

**User Story:** As a user, I want clear indicators of online/offline status and AI capabilities, so that I understand which features are available.

#### Acceptance Criteria

1. WHEN the System detects connectivity changes THEN the System SHALL update online/offline status indicators
2. WHEN the System is offline THEN the System SHALL display "Local AI" badge on chat interface
3. WHEN the System is online THEN the System SHALL display available AI providers (Local, OpenRouter, OpenAI, etc.)
4. WHEN the System performs operations THEN the System SHALL indicate whether using local or cloud resources
5. WHEN the System has pending sync operations THEN the System SHALL show sync queue status
6. WHEN the System completes sync THEN the System SHALL show success notification
7. WHEN the System encounters sync errors THEN the System SHALL display error details and retry options

### Requirement 11: Embedding Model Compatibility

**User Story:** As a system architect, I want embedding models to maintain compatibility with existing Pinecone indices, so that offline and online embeddings work seamlessly together.

#### Acceptance Criteria

1. WHEN the System generates embeddings locally THEN the System SHALL produce vectors with same dimensionality as cloud embeddings
2. WHEN the System uses sentence-transformers/all-MiniLM-L6-v2 THEN the System SHALL generate 384-dimensional embeddings
3. WHEN the System normalizes embeddings THEN the System SHALL use L2 normalization matching cloud implementation
4. WHEN the System compares embeddings THEN the System SHALL use cosine similarity for consistency
5. WHEN the System validates embeddings THEN the System SHALL verify vector dimensions before storage
6. WHEN the System switches between local and cloud embeddings THEN the System SHALL maintain search result quality
7. WHEN embedding format changes THEN the System SHALL migrate existing embeddings automatically

### Requirement 12: Progressive Model Loading

**User Story:** As a user, I want models to load progressively in the background, so that I can start using the app immediately without waiting for large downloads.

#### Acceptance Criteria

1. WHEN the System starts THEN the System SHALL allow app usage before models are downloaded
2. WHEN the System downloads models THEN the System SHALL download in background without blocking UI
3. WHEN the System loads models THEN the System SHALL prioritize embedding models over LLM models
4. WHEN the System downloads models THEN the System SHALL support pause and resume functionality
5. WHEN the System completes model download THEN the System SHALL notify users that offline AI is ready
6. WHEN the System detects interrupted downloads THEN the System SHALL resume from last checkpoint
7. WHEN network conditions are poor THEN the System SHALL adapt download strategy to prevent failures
