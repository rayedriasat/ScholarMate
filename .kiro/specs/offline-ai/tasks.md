# Implementation Plan: Offline AI with Local LLM and Embeddings

## Phase 1: Foundation and Infrastructure

- [ ] 1. Set up project dependencies and platform detection
  - Add `flutter_onnxruntime` package for native platforms using `flutter pub add`
  - Add `llama_cpp_dart` package for LLM inference using `flutter pub add`
  - Create platform detection utility to identify Android/Windows/Web
  - Create capability detection for WebGPU, NNAPI, DirectML
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 2. Extend Drift database schema for offline AI
  - [ ] 2.1 Create `cached_embeddings` table with vector storage
    - Add columns: id, file_id, chunk_index, page_number, content, embedding (JSON), synced, created_at, synced_at
    - Add indices on file_id and synced for efficient queries
    - _Requirements: 6.1_
  
  - [ ] 2.2 Create `local_chat_messages` table for offline chat history
    - Add columns: id, conversation_id, role, content, citations (JSON), generated_locally, synced, created_at, synced_at
    - Add indices on conversation_id and synced
    - _Requirements: 7.1_
  
  - [ ] 2.3 Create `model_metadata` table for installed models
    - Add columns: id, name, type, size_bytes, parameter_count, quantization, local_path, installed_at
    - _Requirements: 5.3_
  
  - [ ] 2.4 Create `sync_queue` table for pending operations
    - Add columns: id, operation_type, data (JSON), retry_count, last_attempt, created_at
    - _Requirements: 1.5, 6.2_
  
  - [ ]* 2.5 Write property test for Drift schema
    - **Property 34: Dimension Validation**
    - **Validates: Requirements 11.5**

- [ ] 3. Create LocalAIEngine interface and factory
  - Define abstract `LocalAIEngine` interface with methods for embeddings, LLM, vector search
  - Create factory method that returns platform-specific implementation
  - Add model lifecycle methods (initialize, load, unload, areModelsLoaded)
  - _Requirements: 4.4_

- [ ]* 4. Write property test for platform detection
  - **Property 2: Platform-Appropriate Backend Selection**
  - **Validates: Requirements 1.2, 1.3, 2.2, 2.3, 4.1, 4.2, 4.3, 4.4**

## Phase 2: Native Platform Implementation (Android/Windows)

- [ ] 5. Implement NativeLocalAIEngine for ONNX Runtime embeddings
  - [ ] 5.1 Create ONNX session loader for sentence-transformers models
    - Load all-MiniLM-L6-v2 model from local storage
    - Configure NNAPI delegate for Android, DirectML for Windows
    - Implement tokenization for input text
    - _Requirements: 1.2, 4.1, 4.2_
  
  - [ ] 5.2 Implement embedding generation with ONNX Runtime
    - Convert text to tokens using tokenizer
    - Run inference through ONNX session
    - Extract 384-dimensional embeddings from output
    - Apply L2 normalization to embeddings
    - _Requirements: 1.1, 1.4, 11.3_
  
  - [ ] 5.3 Add batch embedding generation
    - Process multiple texts in single inference call
    - Implement batching with configurable batch size
    - _Requirements: 1.1_
  
  - [ ]* 5.4 Write property test for embedding generation
    - **Property 1: Embedding Dimension Consistency**
    - **Validates: Requirements 1.4, 11.1**
  
  - [ ]* 5.5 Write property test for L2 normalization
    - **Property 33: L2 Normalization Consistency**
    - **Validates: Requirements 11.3**

- [ ] 6. Implement NativeLocalAIEngine for llama.cpp LLM inference
  - [ ] 6.1 Create llama.cpp model loader
    - Load quantized GGUF models (Q4/Q8 format)
    - Configure context size and thread count
    - Implement model validation for quantization format
    - _Requirements: 2.2, 2.4_
  
  - [ ] 6.2 Implement streaming LLM inference
    - Create prompt template for RAG queries
    - Implement token-by-token streaming generation
    - Add stop token detection
    - Handle context window limits
    - _Requirements: 2.1, 2.5_
  
  - [ ] 6.3 Add hardware acceleration support
    - Enable Metal acceleration on iOS/macOS
    - Enable CUDA/Vulkan on Windows if available
    - Fallback to CPU if GPU unavailable
    - _Requirements: 8.4_
  
  - [ ]* 6.4 Write property test for quantized model format
    - **Property 6: Quantized Model Format**
    - **Validates: Requirements 2.4**
  
  - [ ]* 6.5 Write property test for offline LLM inference
    - **Property 5: Local-Only Offline Operations**
    - **Validates: Requirements 1.1, 2.5, 3.1, 3.4**

- [ ] 7. Implement local vector search in NativeLocalAIEngine
  - [ ] 7.1 Create cosine similarity calculation
    - Implement efficient dot product for normalized vectors
    - Add batch similarity calculation for multiple vectors
    - _Requirements: 3.3, 11.4_
  
  - [ ] 7.2 Implement k-nearest neighbors search
    - Query Drift database for embeddings
    - Calculate similarity scores for all candidates
    - Return top-k results sorted by similarity
    - Support filtering by file IDs
    - _Requirements: 3.2, 3.3_
  
  - [ ]* 7.3 Write property test for cosine similarity ranking
    - **Property 8: Cosine Similarity Ranking**
    - **Validates: Requirements 3.3, 11.4**

## Phase 3: Web Platform Implementation (PWA)

- [ ] 8. Set up JavaScript interop for Transformers.js
  - [ ] 8.1 Create JS bridge for Transformers.js
    - Add Transformers.js library to web assets
    - Create Dart-JS interop layer using `dart:js_interop`
    - Implement promise-to-future conversion
    - _Requirements: 1.3, 4.3_
  
  - [ ] 8.2 Configure WASM and WebGPU backends
    - Detect WebGPU availability in browser
    - Configure Transformers.js to use WebGPU when available
    - Fallback to WASM backend for older browsers
    - _Requirements: 4.5_
  
  - [ ]* 8.3 Write property test for WebGPU fallback
    - **Property 10: WebGPU Fallback**
    - **Validates: Requirements 4.5**

- [ ] 9. Implement WebLocalAIEngine for Transformers.js embeddings
  - [ ] 9.1 Load sentence-transformers model via Transformers.js
    - Initialize pipeline with 'feature-extraction' task
    - Load all-MiniLM-L6-v2 model from CDN or cache
    - Configure pooling and normalization
    - _Requirements: 1.3_
  
  - [ ] 9.2 Implement embedding generation via JS interop
    - Call Transformers.js embedding pipeline from Dart
    - Extract 384-dimensional vectors from output
    - Handle async operations with proper error handling
    - _Requirements: 1.1, 1.4_
  
  - [ ]* 9.3 Write property test for web embedding generation
    - **Property 1: Embedding Dimension Consistency**
    - **Validates: Requirements 1.4, 11.1**

- [ ] 10. Set up JavaScript interop for WebLLM
  - [ ] 10.1 Create JS bridge for WebLLM
    - Add WebLLM library to web assets
    - Create Dart-JS interop for MLCEngine
    - Implement streaming response handling
    - _Requirements: 2.3, 4.3_
  
  - [ ] 10.2 Configure WebGPU for WebLLM
    - Initialize WebLLM with WebGPU backend
    - Set up model loading progress callbacks
    - Handle WebGPU context loss and recovery
    - _Requirements: 4.5, 4.6_

- [ ] 11. Implement WebLocalAIEngine for WebLLM inference
  - [ ] 11.1 Load quantized LLM models via WebLLM
    - Initialize MLCEngine with model ID
    - Load Phi-3-mini or Llama-3.2 models
    - Show progress during model download
    - _Requirements: 2.3, 2.4, 4.6_
  
  - [ ] 11.2 Implement streaming chat completion
    - Create chat completion requests with context
    - Stream tokens via async generator
    - Handle stop sequences and max tokens
    - _Requirements: 2.1, 2.5_
  
  - [ ]* 11.3 Write property test for web LLM inference
    - **Property 5: Local-Only Offline Operations**
    - **Validates: Requirements 1.1, 2.5, 3.1, 3.4**

- [ ] 12. Implement local vector search in WebLocalAIEngine
  - Reuse cosine similarity logic from native implementation
  - Query Drift WASM database for embeddings
  - Return top-k results with file filtering
  - _Requirements: 3.2, 3.3_

## Phase 4: Model Management

- [ ] 13. Implement ModelManager service
  - [ ] 13.1 Create model catalog with metadata
    - Define available embedding models (MiniLM-L6, MiniLM-L12, BGE-small)
    - Define available LLM models (Phi-3-mini, Llama-3.2-1B, Llama-3.2-3B, Qwen2-1.5B)
    - Include size, memory requirements, quality ratings for each
    - _Requirements: 9.1, 9.2, 9.3_
  
  - [ ] 13.2 Implement model download with progress tracking
    - Download models from HuggingFace or CDN
    - Show progress with bytes downloaded, total size, speed
    - Support pause and resume functionality
    - Save to platform-appropriate storage location
    - _Requirements: 4.6, 5.2, 5.3, 12.4_
  
  - [ ] 13.3 Add checkpoint-based resume for interrupted downloads
    - Save download progress at regular intervals
    - Resume from last checkpoint on restart
    - Verify partial downloads with checksums
    - _Requirements: 12.6_
  
  - [ ] 13.4 Implement adaptive download strategy
    - Detect network speed and adjust chunk sizes
    - Retry failed chunks with exponential backoff
    - Switch to smaller chunks on poor connections
    - _Requirements: 12.7_
  
  - [ ]* 13.5 Write property test for progress reporting
    - **Property 11: Progress Reporting**
    - **Validates: Requirements 4.6, 5.2**
  
  - [ ]* 13.6 Write property test for download pause/resume
    - **Property 39: Download Pause and Resume**
    - **Validates: Requirements 12.4**
  
  - [ ]* 13.7 Write property test for checkpoint resume
    - **Property 40: Checkpoint-Based Resume**
    - **Validates: Requirements 12.6**

- [ ] 14. Implement model storage and deletion
  - [ ] 14.1 Store models in platform-specific directories
    - Android: app internal storage
    - Windows: AppData/Local
    - Web: IndexedDB or Cache API
    - _Requirements: 5.3_
  
  - [ ] 14.2 Implement model deletion
    - Remove model files from storage
    - Update model metadata in Drift
    - Free storage space and update UI
    - _Requirements: 5.4_
  
  - [ ] 14.3 Add storage validation before downloads
    - Check available storage space
    - Warn users if insufficient space
    - Suggest models to delete if needed
    - _Requirements: 5.7_
  
  - [ ]* 14.4 Write property test for model deletion
    - **Property 13: Model Deletion Frees Storage**
    - **Validates: Requirements 5.4**
  
  - [ ]* 14.5 Write property test for storage validation
    - **Property 15: Storage Validation**
    - **Validates: Requirements 5.7**

- [ ] 15. Implement model recommendation system
  - Detect device capabilities (RAM, storage, GPU)
  - Recommend appropriate model sizes based on capabilities
  - Show warnings for models that may not run well
  - _Requirements: 9.6_

- [ ]* 16. Write property test for device-appropriate recommendations
  - **Property 28: Device-Appropriate Recommendations**
  - **Validates: Requirements 9.6**

## Phase 5: Embedding Service and Sync

- [ ] 17. Implement EmbeddingService orchestration
  - [ ] 17.1 Create embedding generation orchestrator
    - Route to local or cloud based on connectivity and user preference
    - Generate embeddings using LocalAIEngine when offline
    - Fallback to HuggingFace API when local fails
    - _Requirements: 1.1, 1.5_
  
  - [ ] 17.2 Implement document indexing pipeline
    - Split documents into chunks
    - Generate embeddings for all chunks
    - Store embeddings in Drift with metadata
    - Queue for sync if offline
    - _Requirements: 1.5, 6.1_
  
  - [ ]* 17.3 Write property test for offline embedding queue
    - **Property 3: Offline Embedding Queue**
    - **Validates: Requirements 1.5, 6.1**

- [ ] 18. Implement LocalVectorStore DAO
  - [ ] 18.1 Create embedding insertion methods
    - Insert single embedding with metadata
    - Batch insert multiple embeddings
    - Handle duplicate detection
    - _Requirements: 6.1_
  
  - [ ] 18.2 Implement vector similarity search
    - Query embeddings by file IDs
    - Calculate cosine similarity for query vector
    - Return top-k results sorted by similarity
    - _Requirements: 3.2, 3.3_
  
  - [ ] 18.3 Add sync queue management
    - Query unsynced embeddings
    - Mark embeddings as synced after upload
    - Delete embeddings by file ID
    - _Requirements: 1.5, 6.2_
  
  - [ ]* 18.4 Write property test for offline data source
    - **Property 9: Offline Data Source**
    - **Validates: Requirements 3.2**

- [ ] 19. Implement SyncService for embeddings
  - [ ] 19.1 Create automatic sync trigger on connectivity
    - Listen to connectivity changes
    - Trigger sync when going online
    - Debounce rapid connectivity changes
    - _Requirements: 1.6, 6.2_
  
  - [ ] 19.2 Implement batch upload to Pinecone
    - Query unsynced embeddings from Drift
    - Group embeddings into batches (100 per batch)
    - Upload batches to Pinecone with metadata
    - Mark as synced after successful upload
    - _Requirements: 6.3_
  
  - [ ] 19.3 Add conflict resolution for embeddings
    - Detect conflicts by comparing timestamps
    - Apply last-write-wins strategy
    - Update local or remote based on resolution
    - _Requirements: 6.4_
  
  - [ ] 19.4 Implement exponential backoff retry
    - Retry failed uploads with increasing delays (1s, 2s, 4s, 8s, ...)
    - Max retry count of 5 attempts
    - Preserve failed items in queue for manual retry
    - _Requirements: 6.7_
  
  - [ ]* 19.5 Write property test for automatic sync
    - **Property 4: Automatic Sync on Connectivity**
    - **Validates: Requirements 1.6, 6.2, 7.2**
  
  - [ ]* 19.6 Write property test for batch optimization
    - **Property 16: Batch Sync Optimization**
    - **Validates: Requirements 6.3**
  
  - [ ]* 19.7 Write property test for conflict resolution
    - **Property 17: Last-Write-Wins Conflict Resolution**
    - **Validates: Requirements 6.4, 7.4**
  
  - [ ]* 19.8 Write property test for exponential backoff
    - **Property 19: Exponential Backoff Retry**
    - **Validates: Requirements 6.7, 7.7**

## Phase 6: Offline RAG Pipeline

- [ ] 20. Implement LocalLLMService
  - [ ] 20.1 Create model loading and lifecycle management
    - Load model using LocalAIEngine
    - Implement lazy loading (load on first use)
    - Add model unloading after idle timeout
    - _Requirements: 8.1, 8.2_
  
  - [ ] 20.2 Implement streaming response generation
    - Create prompt template for RAG queries
    - Stream tokens from local LLM
    - Handle stop sequences and max tokens
    - _Requirements: 2.1, 2.5_
  
  - [ ]* 20.3 Write property test for lazy loading
    - **Property 21: Lazy Model Loading**
    - **Validates: Requirements 8.1**
  
  - [ ]* 20.4 Write property test for idle unloading
    - **Property 22: Idle Model Unloading**
    - **Validates: Requirements 8.2**

- [ ] 21. Enhance RAGService for offline queries
  - [ ] 21.1 Implement offline RAG query pipeline
    - Generate query embedding using LocalAIEngine
    - Search local vector store for relevant chunks
    - Retrieve top-k chunks with file filtering
    - Generate response using LocalLLMService
    - Format citations from retrieved chunks
    - _Requirements: 3.1, 3.2, 3.4_
  
  - [ ] 21.2 Add dual-mode RAG orchestration
    - Detect online/offline status
    - Route to offline pipeline when offline
    - Route to cloud pipeline when online
    - Allow user to force local mode when online
    - _Requirements: 2.1, 2.6, 3.5_
  
  - [ ] 21.3 Implement offline availability check
    - Verify models are loaded
    - Check if embeddings exist for selected files
    - Return availability status to UI
    - _Requirements: 2.1_
  
  - [ ]* 21.4 Write property test for offline RAG pipeline
    - **Property 5: Local-Only Offline Operations**
    - **Validates: Requirements 1.1, 2.5, 3.1, 3.4**

## Phase 7: Chat History Sync

- [ ] 22. Implement chat history persistence
  - [ ] 22.1 Save chat messages to Drift
    - Store user and assistant messages
    - Include citations and metadata
    - Mark messages as generated locally or via cloud
    - _Requirements: 7.1_
  
  - [ ] 22.2 Load chat history from appropriate source
    - Fetch from Supabase when online
    - Fetch from Drift when offline
    - Merge local and remote messages by timestamp
    - _Requirements: 7.5_
  
  - [ ]* 22.3 Write property test for connectivity-based data source
    - **Property 20: Connectivity-Based Data Source**
    - **Validates: Requirements 7.5**

- [ ] 23. Implement chat history sync
  - [ ] 23.1 Sync chat messages to Supabase
    - Query unsynced messages from Drift
    - Upload messages with content, timestamps, citations
    - Mark as synced after successful upload
    - _Requirements: 7.2, 7.3_
  
  - [ ] 23.2 Add conflict resolution for chat history
    - Detect conflicts by conversation ID and timestamp
    - Merge conversations by timestamp order
    - Preserve all messages from both sources
    - _Requirements: 7.4_
  
  - [ ] 23.3 Implement retry logic for failed sync
    - Retry with exponential backoff
    - Preserve local messages on failure
    - Show sync status in UI
    - _Requirements: 7.7_
  
  - [ ]* 23.4 Write property test for metadata preservation
    - **Property 18: Metadata Preservation**
    - **Validates: Requirements 6.5, 7.3**

## Phase 8: Resource Management

- [ ] 24. Implement memory management
  - [ ] 24.1 Add low memory detection
    - Monitor available memory on device
    - Detect low memory conditions
    - Trigger automatic model unloading
    - Show warning to users
    - _Requirements: 8.3_
  
  - [ ] 24.2 Implement streaming and batching for large documents
    - Process documents in chunks to avoid memory spikes
    - Stream embeddings to database incrementally
    - Use batch processing for multiple documents
    - _Requirements: 8.6_
  
  - [ ]* 24.3 Write property test for low memory protection
    - **Property 23: Low Memory Protection**
    - **Validates: Requirements 8.3**
  
  - [ ]* 24.4 Write property test for streaming and batching
    - **Property 25: Streaming and Batching**
    - **Validates: Requirements 8.6**

- [ ] 25. Implement hardware acceleration
  - Detect available acceleration (GPU, Neural Engine, NNAPI, DirectML)
  - Configure LocalAIEngine to use acceleration
  - Fallback to CPU if acceleration unavailable
  - _Requirements: 8.4_

- [ ]* 26. Write property test for hardware acceleration
  - **Property 24: Hardware Acceleration Usage**
  - **Validates: Requirements 8.4**

- [ ] 27. Implement power-saving mode
  - Detect battery power vs plugged in
  - Offer smaller models when on battery
  - Reduce inference frequency in power-saving mode
  - _Requirements: 8.5_

- [ ] 28. Add resource monitoring
  - Track memory usage during operations
  - Monitor battery drain during inference
  - Provide statistics to users
  - Log resource metrics for debugging
  - _Requirements: 8.7_

## Phase 9: UI Integration

- [ ] 29. Create model management UI
  - [ ] 29.1 Build model selection screen
    - Display available models with size, memory, quality
    - Show installed models with storage usage
    - Add download buttons with progress indicators
    - Add delete buttons for installed models
    - _Requirements: 5.2, 5.4, 9.3_
  
  - [ ] 29.2 Add model configuration warnings
    - Warn about storage requirements before download
    - Warn about re-indexing when changing embedding models
    - Show estimated time for operations
    - _Requirements: 9.7_
  
  - [ ]* 29.3 Write property test for model information completeness
    - **Property 26: Model Information Completeness**
    - **Validates: Requirements 9.3**
  
  - [ ]* 29.4 Write property test for configuration warnings
    - **Property 29: Configuration Change Warnings**
    - **Validates: Requirements 9.7**

- [ ] 30. Implement online/offline status indicators
  - [ ] 30.1 Add connectivity status badge
    - Show "Online" or "Offline" in app bar
    - Update in real-time on connectivity changes
    - _Requirements: 10.1_
  
  - [ ] 30.2 Add AI mode indicators
    - Show "Local AI" badge when using offline mode
    - Display available providers when online
    - Indicate current provider in chat interface
    - _Requirements: 10.2, 10.3, 10.4_
  
  - [ ] 30.3 Add sync status indicators
    - Show pending sync count
    - Display sync progress during upload
    - Show success/error notifications
    - _Requirements: 10.5, 10.6, 10.7_
  
  - [ ]* 30.4 Write property test for status indicator updates
    - **Property 30: Status Indicator Updates**
    - **Validates: Requirements 10.1, 10.4, 10.5, 6.6**

- [ ] 31. Add provider selection UI
  - Display all available providers when online
  - Allow users to select preferred provider
  - Show "Local" option alongside cloud providers
  - Persist user preference
  - _Requirements: 2.6, 10.3_

- [ ]* 32. Write property test for provider display
  - **Property 31: Provider Display**
  - **Validates: Requirements 10.3**

- [ ] 33. Implement error message UI
  - Show clear error messages for all failure types
  - Provide actionable suggestions (e.g., "Free up storage", "Check connection")
  - Add retry buttons for recoverable errors
  - Add "Use cloud instead" option when local fails
  - _Requirements: 1.7, 2.7, 3.7, 10.7_

- [ ]* 34. Write property test for error message clarity
  - **Property 32: Error Message Clarity**
  - **Validates: Requirements 1.7, 2.7, 3.7, 10.7**

- [ ] 35. Add chat history indicators
  - Mark messages generated locally vs cloud
  - Show sync status for each message
  - Display citations with file navigation
  - _Requirements: 7.6_

## Phase 10: Progressive Loading and Onboarding

- [ ] 36. Implement progressive model loading
  - [ ] 36.1 Enable app usage before model downloads
    - Allow document viewing and management
    - Show "Download models for AI features" prompt
    - Enable cloud AI features immediately
    - _Requirements: 12.1_
  
  - [ ] 36.2 Implement background model downloads
    - Download models in background without blocking UI
    - Use Web Workers (web) or isolates (native)
    - Show progress in notification or status bar
    - _Requirements: 12.2_
  
  - [ ] 36.3 Prioritize embedding models over LLM
    - Download embedding model first
    - Enable document indexing as soon as embedding model ready
    - Download LLM model second
    - Enable offline chat when LLM ready
    - _Requirements: 12.3_
  
  - [ ]* 36.4 Write property test for non-blocking startup
    - **Property 36: Non-Blocking Startup**
    - **Validates: Requirements 12.1**
  
  - [ ]* 36.5 Write property test for background downloads
    - **Property 37: Background Downloads**
    - **Validates: Requirements 12.2**
  
  - [ ]* 36.6 Write property test for embedding priority
    - **Property 38: Embedding Model Priority**
    - **Validates: Requirements 12.3**

- [ ] 37. Create first-run onboarding flow
  - Show welcome screen explaining offline AI features
  - Prompt users to download recommended models
  - Explain storage requirements and benefits
  - Allow users to skip and use cloud-only mode
  - _Requirements: 5.1_

- [ ] 38. Implement model readiness notifications
  - Show notification when embedding model ready
  - Show notification when LLM model ready
  - Update UI to enable offline features progressively
  - _Requirements: 12.5_

## Phase 11: Testing and Optimization

- [ ] 39. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 40. Implement graceful degradation
  - [ ] 40.1 Add platform capability checks
    - Detect missing ML frameworks
    - Detect insufficient memory or storage
    - Disable local AI features gracefully
    - _Requirements: 4.7_
  
  - [ ] 40.2 Implement cloud-only fallback mode
    - Continue with cloud AI when local unavailable
    - Show clear messaging about why local is disabled
    - Offer to retry or download models
    - _Requirements: 4.7_
  
  - [ ]* 40.3 Write property test for graceful degradation
    - **Property 12: Graceful Degradation**
    - **Validates: Requirements 4.7**

- [ ] 41. Add model re-indexing logic
  - Detect when embedding model changes
  - Trigger re-indexing of all documents
  - Show progress during re-indexing
  - Preserve old embeddings until new ones ready
  - _Requirements: 9.4_

- [ ]* 42. Write property test for dimension change re-indexing
  - **Property 27: Dimension Change Re-indexing**
  - **Validates: Requirements 9.4**

- [ ] 43. Implement embedding format migration
  - Detect embedding format changes
  - Migrate existing embeddings to new format
  - Preserve metadata during migration
  - Show progress to users
  - _Requirements: 11.7_

- [ ]* 44. Write property test for format migration
  - **Property 35: Format Migration**
  - **Validates: Requirements 11.7**

- [ ] 45. Implement preference persistence
  - Save selected models to shared preferences
  - Save AI mode preference (local/cloud/auto)
  - Save sync settings
  - Restore preferences on app restart
  - _Requirements: 5.6, 9.5_

- [ ]* 46. Write property test for preference persistence
  - **Property 14: Preference Persistence**
  - **Validates: Requirements 5.6, 9.5**

- [ ] 47. Performance optimization
  - Profile embedding generation speed
  - Profile LLM inference speed
  - Profile vector search latency
  - Optimize bottlenecks to meet performance targets
  - _Requirements: All_

- [ ] 48. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
