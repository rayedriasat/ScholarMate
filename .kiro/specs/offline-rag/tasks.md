# Implementation Plan — Offline RAG

## Task List

- [ ] 1. Add dependencies and setup model manager



  - Add flutter_llama, onnxruntime, and http packages
  - Create ModelManagerService with download/verify/delete methods
  - Create model catalog JSON with Gemma-2B and TinyLlama download URLs
  - Add models table to Drift schema
  - _Requirements: 1.1, 1.2, 1.5, 1.6_

- [ ]* 1.1 Write property test for model download integrity
  - **Property 1: Model download integrity**
  - **Validates: Requirements 1.5**

- [ ] 2. Implement local LLM service
  - Create LocalLLMService wrapping flutter_llama
  - Implement loadModel() with GPU detection and configuration
  - Implement generateStream() for token streaming
  - Add model auto-unload after 5 minutes inactivity
  - Integrate into existing AI chat UI with mode indicator
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 8.3_

- [ ]* 2.1 Write property test for offline mode routing
  - **Property 6: Offline mode uses local models**
  - **Validates: Requirements 2.3, 4.2, 5.2**

- [ ]* 2.2 Write property test for context window limit
  - **Property 9: Context window limit**
  - **Validates: Requirements 2.5**

- [ ] 3. Implement local embeddings service
  - Create LocalEmbeddingsService wrapping onnxruntime
  - Download and bundle all-MiniLM-L6-v2 ONNX model
  - Implement generateEmbeddings() with batch processing
  - Run embedding generation in background isolate
  - _Requirements: 3.1, 3.2, 3.5_

- [ ]* 3.1 Write property test for embedding storage round-trip
  - **Property 11: Embedding storage round-trip**
  - **Validates: Requirements 3.4**

- [ ] 4. Implement offline vector store
  - Add vector_embeddings and document_chunks tables to Drift
  - Create OfflineVectorStoreService with indexDocument() and search()
  - Implement cosine similarity search
  - Add source file filtering
  - _Requirements: 3.3, 3.4, 4.1, 4.3, 4.4, 4.5_

- [ ]* 4.1 Write property test for cosine similarity bounds
  - **Property 13: Cosine similarity bounds**
  - **Validates: Requirements 4.1**

- [ ]* 4.2 Write property test for source file filtering
  - **Property 15: Source file filtering**
  - **Validates: Requirements 4.4**

- [ ] 5. Implement hybrid RAG orchestrator
  - Create HybridRAGOrchestrator that routes between cloud/local
  - Detect online/offline status and route accordingly
  - Implement forced offline mode setting
  - Update existing RAG query endpoint to use orchestrator
  - Ensure consistent citation format for both modes
  - _Requirements: 5.1, 5.2, 5.3, 5.5, 5.6_

- [ ]* 5.1 Write property test for hybrid mode routing
  - **Property 7: Online mode uses cloud models**
  - **Validates: Requirements 5.1**

- [ ]* 5.2 Write property test for citation format consistency
  - **Property 18: Citation format consistency**
  - **Validates: Requirements 5.6**

- [ ] 6. Implement chat history sync
  - Add chat_messages table to Drift and Supabase
  - Create ChatHistoryService with sync methods
  - Implement conflict resolution (last-write-wins)
  - Add sync status indicators to chat UI
  - Auto-sync when connectivity restored
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ]* 6.1 Write property test for chat sync completeness
  - **Property 22: Chat message sync completeness**
  - **Validates: Requirements 7.1, 7.2, 7.3**

- [ ]* 6.2 Write property test for conflict resolution
  - **Property 24: Conflict resolution by timestamp**
  - **Validates: Requirements 7.5**

- [ ] 7. Add model management UI
  - Create model download screen with available models list
  - Show device capabilities and recommendations
  - Display download progress with pause/resume
  - Add model deletion and storage management
  - Show currently loaded model and memory usage
  - _Requirements: 1.1, 1.4, 1.7, 9.1, 9.2, 9.3_

- [ ] 8. Implement web platform support
  - Add llama.cpp WASM build loading via JS interop
  - Use onnxruntime-web for embeddings
  - Store models in IndexedDB
  - Use Web Workers for inference
  - Add browser compatibility checks
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.6_

- [ ]* 8.1 Write property test for web model size limits
  - **Property 19: Web model size limits**
  - **Validates: Requirements 6.5**

- [ ] 9. Add performance optimizations and error handling
  - Implement concurrent embedding limit (5 chunks)
  - Add low-power mode with reduced parameters
  - Implement graceful degradation when AI fails
  - Add error logging for all AI operations
  - Add "Reset AI" option in settings
  - _Requirements: 8.1, 8.2, 8.6, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ]* 9.1 Write property test for graceful degradation
  - **Property 34: Graceful degradation**
  - **Validates: Requirements 10.6**

- [ ] 10. Final integration and testing
  - Test end-to-end offline RAG flow on all platforms
  - Verify online/offline switching works seamlessly
  - Test with real documents and queries
  - Ensure all tests pass, ask the user if questions arise
