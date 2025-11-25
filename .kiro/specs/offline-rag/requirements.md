# Requirements Document — Offline RAG

## Introduction

This feature extends ScholarMate with offline AI capabilities, enabling users to perform RAG (Retrieval-Augmented Generation) queries, generate embeddings, and chat with documents entirely on their device without internet connectivity. The system uses local LLM inference and embedding generation, with cloud sync when online. This is an MVP focused on simplicity and cross-platform support (Android, Windows, Web/PWA).

## Glossary

- **Local_LLM**: On-device language model running via llama.cpp (Android/Desktop) or WASM (Web)
- **Local_Embeddings**: On-device embedding generation using ONNX Runtime with sentence-transformers models
- **GGUF_Model**: Quantized model format used by llama.cpp (e.g., Gemma-2B, TinyLlama)
- **ONNX_Model**: Optimized model format for embedding generation (e.g., all-MiniLM-L6-v2)
- **Offline_Vector_Store**: Local Drift database storing embeddings and chunks
- **Chat_History**: Conversation history stored locally and synced to Supabase when online
- **Model_Manager**: Service for downloading and managing local models
- **Hybrid_Mode**: System automatically uses local models offline, cloud models online

## Requirements

### Requirement 1: Local Model Management

**User Story:** As a user, I want to download and manage AI models on my device, so that I can use AI features offline.

#### Acceptance Criteria

1. THE Flutter_Client SHALL provide a model management UI showing available models with size and capabilities
2. WHEN a user selects a model to download, THE Flutter_Client SHALL download the GGUF model file and store it locally
3. THE Flutter_Client SHALL download ONNX embedding models (all-MiniLM-L6-v2, 80MB) for local embedding generation
4. THE Flutter_Client SHALL display download progress with pause/resume capability
5. THE Flutter_Client SHALL verify model integrity after download using checksums
6. THE Flutter_Client SHALL allow users to delete downloaded models to free storage space
7. THE Flutter_Client SHALL recommend lightweight models for mobile (Gemma-2B Q4, <1GB) and desktop (Gemma-2B Q5, <2GB)

### Requirement 2: Local LLM Inference

**User Story:** As a user, I want to run AI chat on my device, so that I can ask questions about documents without internet.

#### Acceptance Criteria

1. THE Flutter_Client SHALL initialize flutter_llama plugin for Android and Desktop platforms
2. THE Flutter_Client SHALL load GGUF models with GPU acceleration when available (Metal for iOS/macOS, Vulkan for Android)
3. WHEN a user sends a chat message offline, THE Flutter_Client SHALL use Local_LLM for inference
4. THE Flutter_Client SHALL stream responses token-by-token for better UX
5. THE Flutter_Client SHALL limit context window to 2048 tokens for memory efficiency
6. THE Flutter_Client SHALL display inference speed (tokens/second) and model info in settings

### Requirement 3: Local Embedding Generation

**User Story:** As a user, I want my documents indexed locally, so that I can search them offline.

#### Acceptance Criteria

1. THE Flutter_Client SHALL use onnxruntime plugin to run embedding models locally
2. WHEN a user uploads a PDF offline, THE Flutter_Client SHALL extract text and generate embeddings using Local_Embeddings
3. THE Flutter_Client SHALL chunk documents into 400-character segments with 40-character overlap
4. THE Flutter_Client SHALL store embeddings in Offline_Vector_Store (Drift database)
5. THE Flutter_Client SHALL process embeddings in background isolate to prevent UI jank
6. THE Flutter_Client SHALL display indexing progress with estimated time remaining

### Requirement 4: Offline Vector Search

**User Story:** As a user, I want to search my documents offline, so that I can find relevant information without internet.

#### Acceptance Criteria

1. THE Flutter_Client SHALL implement cosine similarity search over local embeddings
2. WHEN a user asks a question offline, THE Flutter_Client SHALL generate query embedding using Local_Embeddings
3. THE Flutter_Client SHALL retrieve top 5 most relevant chunks from Offline_Vector_Store
4. THE Flutter_Client SHALL filter results by selected source files
5. THE Flutter_Client SHALL return results with file_id, file_name, page_number, and relevance score
6. THE Flutter_Client SHALL complete search queries in under 500ms for libraries up to 100 documents

### Requirement 5: Hybrid Online/Offline RAG

**User Story:** As a user, I want the system to automatically use cloud or local AI based on connectivity, so that I get the best experience.

#### Acceptance Criteria

1. WHEN online, THE ScholarMate_System SHALL use GROQ API for chat and embeddings (faster, more accurate)
2. WHEN offline, THE ScholarMate_System SHALL use Local_LLM and Local_Embeddings automatically
3. THE Flutter_Client SHALL display current mode (Online/Offline) in chat interface
4. WHEN connectivity is restored, THE Flutter_Client SHALL sync offline-generated chat history to Supabase
5. THE Flutter_Client SHALL allow users to force offline mode even when online for privacy
6. THE ScholarMate_System SHALL maintain consistent citation format regardless of online/offline mode

### Requirement 6: Web Platform Support (PWA)

**User Story:** As a web user, I want offline AI capabilities in my browser, so that I can work without backend dependency.

#### Acceptance Criteria

1. THE Flutter_Client SHALL use llama.cpp WASM build for web platform LLM inference
2. THE Flutter_Client SHALL use onnxruntime-web for embedding generation in browser
3. THE Flutter_Client SHALL store models in IndexedDB for offline PWA access
4. THE Flutter_Client SHALL display browser compatibility warnings for unsupported features
5. THE Flutter_Client SHALL limit web models to smaller sizes (TinyLlama 1.1B Q4, ~600MB) for reasonable load times
6. THE Flutter_Client SHALL use Web Workers for inference to keep UI responsive

### Requirement 7: Chat History Sync

**User Story:** As a user, I want my chat history synced across devices, so that I can continue conversations anywhere.

#### Acceptance Criteria

1. THE Flutter_Client SHALL store all chat messages in Local_Cache with sync_status flag
2. WHEN online, THE Flutter_Client SHALL sync chat history to Supabase chat_messages table
3. THE Flutter_Client SHALL include message content, citations, timestamp, and model_used in sync
4. WHEN switching devices, THE Flutter_Client SHALL fetch and merge chat history from Supabase
5. THE Flutter_Client SHALL resolve conflicts using last-write-wins with timestamp comparison
6. THE Flutter_Client SHALL allow users to delete chat history locally and remotely

### Requirement 8: Performance Optimization

**User Story:** As a user with limited device resources, I want efficient AI processing, so that my device remains responsive.

#### Acceptance Criteria

1. THE Flutter_Client SHALL limit concurrent embedding generation to 5 chunks at a time
2. THE Flutter_Client SHALL use quantized models (Q4_K_M) to reduce memory usage
3. THE Flutter_Client SHALL implement model unloading after 5 minutes of inactivity
4. THE Flutter_Client SHALL display memory usage and allow users to adjust batch sizes
5. THE Flutter_Client SHALL prioritize UI thread over background inference tasks
6. THE Flutter_Client SHALL provide low-power mode that reduces inference quality for battery savings

### Requirement 9: Model Recommendations

**User Story:** As a user, I want smart model recommendations, so that I choose the right model for my device.

#### Acceptance Criteria

1. THE Flutter_Client SHALL detect device capabilities (RAM, storage, GPU) on first launch
2. THE Flutter_Client SHALL recommend models based on device specs (mobile: Gemma-2B Q4, desktop: Gemma-2B Q5, web: TinyLlama Q4)
3. THE Flutter_Client SHALL warn users when selecting models too large for their device
4. THE Flutter_Client SHALL provide model comparison showing speed vs quality tradeoffs
5. THE Flutter_Client SHALL allow users to test models with sample queries before full download
6. THE Flutter_Client SHALL display estimated inference speed based on device benchmarks

### Requirement 10: Fallback and Error Handling

**User Story:** As a user, I want graceful degradation when local AI fails, so that I can still use the app.

#### Acceptance Criteria

1. WHEN Local_LLM fails to load, THE Flutter_Client SHALL display error message and suggest cloud mode
2. WHEN device runs out of memory during inference, THE Flutter_Client SHALL cancel operation and suggest smaller model
3. WHEN embedding generation fails, THE Flutter_Client SHALL queue document for retry when resources available
4. THE Flutter_Client SHALL log all AI errors to local storage for debugging
5. THE Flutter_Client SHALL provide "Reset AI" option that clears models and cache
6. THE Flutter_Client SHALL continue functioning for non-AI features when AI components fail
