# Design Document: Offline AI with Local LLM and Embeddings

## Overview

This design extends ScholarMate's AI capabilities to support complete offline operation through local embedding generation and LLM inference. The architecture maintains the existing cloud-based RAG system while adding a parallel offline-first pipeline that syncs when connectivity is available.

### Key Design Principles

1. **Offline-First**: All AI operations work without internet, syncing opportunistically
2. **Platform-Optimized**: Use best-available ML framework for each platform (ONNX/llama.cpp for native, Transformers.js/WebLLM for web)
3. **Backward Compatible**: Existing cloud-based RAG continues to work unchanged
4. **Resource-Conscious**: Lazy loading, model unloading, and memory management
5. **Seamless Sync**: Embeddings and chat history sync across devices transparently

### Technology Stack

**Native Platforms (Android, Windows):**
- Embeddings: ONNX Runtime via `flutter_onnxruntime` package
- LLM: llama.cpp via `llama_cpp_dart` package
- Storage: Drift SQLite database

**Web Platform (PWA):**
- Embeddings: Transformers.js with WASM/WebGPU backend
- LLM: WebLLM with WebGPU acceleration
- Storage: Drift with sqlite3 WASM

**Sync Infrastructure:**
- Vector sync: Pinecone (existing)
- Metadata sync: Supabase (existing)
- Conflict resolution: Last-write-wins with timestamps

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │   AI Service     │         │   Sync Service   │          │
│  │  (Orchestrator)  │◄────────┤  (Background)    │          │
│  └────────┬─────────┘         └──────────────────┘          │
│           │                                                   │
│  ┌────────▼─────────┐         ┌──────────────────┐          │
│  │  Local AI Engine │         │  Cloud AI Engine │          │
│  ├──────────────────┤         ├──────────────────┤          │
│  │ • Embedding Gen  │         │ • HuggingFace API│          │
│  │ • LLM Inference  │         │ • GROQ/OpenRouter│          │
│  │ • Vector Search  │         │ • Pinecone Search│          │
│  └────────┬─────────┘         └────────┬─────────┘          │
│           │                            │                     │
│  ┌────────▼────────────────────────────▼─────────┐          │
│  │         Drift Database (Local Cache)           │          │
│  │  • Documents  • Embeddings  • Chat History    │          │
│  └────────────────────────────────────────────────┘          │
│                                                               │
└───────────────────────────┬───────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  Network Layer │
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌───────▼────────┐  ┌──────▼──────┐
│   Pinecone     │  │   Supabase     │  │   Backend   │
│ (Vector Store) │  │  (Metadata)    │  │  (FastAPI)  │
└────────────────┘  └────────────────┘  └─────────────┘
```

### Component Interaction Flow

**Offline Document Indexing:**
```
User uploads PDF → Extract text → Generate embeddings (local) → 
Store in Drift → Queue for sync → Sync to Pinecone when online
```

**Offline RAG Query:**
```
User asks question → Generate query embedding (local) → 
Search Drift vectors → Retrieve chunks → Generate answer (local LLM) → 
Display with citations
```

**Online RAG Query:**
```
User asks question → Generate query embedding (local/cloud) → 
Search Pinecone → Retrieve chunks → Generate answer (user's provider) → 
Display with citations
```

## Components and Interfaces

### 1. LocalAIEngine (Flutter Service)

**Responsibilities:**
- Manage local ML model lifecycle
- Generate embeddings using platform-specific backend
- Perform LLM inference using platform-specific backend
- Execute local vector search

**Interface:**
```dart
abstract class LocalAIEngine {
  // Model Management
  Future<void> initialize();
  Future<void> loadModels({String? embeddingModel, String? llmModel});
  Future<void> unloadModels();
  Future<bool> areModelsLoaded();
  
  // Embedding Generation
  Future<List<double>> generateEmbedding(String text);
  Future<List<List<double>>> generateEmbeddings(List<String> texts);
  
  // LLM Inference
  Stream<String> generateResponse(String prompt, {int maxTokens = 1000});
  Future<String> generateResponseSync(String prompt, {int maxTokens = 1000});
  
  // Vector Search
  Future<List<SearchResult>> searchVectors(
    List<double> queryEmbedding,
    {int topK = 5, List<String>? fileIds}
  );
  
  // Resource Management
  Future<ModelInfo> getModelInfo();
  Future<void> clearCache();
}
```

**Platform Implementations:**

```dart
// Native (Android, Windows)
class NativeLocalAIEngine implements LocalAIEngine {
  late OnnxRuntimeSession _embeddingSession;
  late LlamaCppModel _llmModel;
  
  // Uses flutter_onnxruntime for embeddings
  // Uses llama_cpp_dart for LLM
}

// Web (PWA)
class WebLocalAIEngine implements LocalAIEngine {
  late TransformersJsEmbedding _embeddingModel;
  late WebLLMEngine _llmEngine;
  
  // Uses Transformers.js via JS interop
  // Uses WebLLM via JS interop
}
```

### 2. EmbeddingService (Flutter Service)

**Responsibilities:**
- Orchestrate embedding generation (local vs cloud)
- Manage embedding cache in Drift
- Queue embeddings for sync

**Interface:**
```dart
class EmbeddingService {
  Future<List<double>> generateEmbedding(
    String text,
    {bool forceLocal = false}
  );
  
  Future<void> indexDocument(
    String fileId,
    List<DocumentChunk> chunks,
    {bool offline = false}
  );
  
  Future<List<CachedEmbedding>> getCachedEmbeddings(String fileId);
  
  Future<void> syncEmbeddings();
  
  Stream<SyncProgress> get syncProgress;
}
```

### 3. LocalVectorStore (Drift DAO)

**Responsibilities:**
- Store embeddings in SQLite
- Perform cosine similarity search
- Manage embedding metadata

**Schema:**
```dart
@DataClassName('CachedEmbedding')
class CachedEmbeddings extends Table {
  TextColumn get id => text()();
  TextColumn get fileId => text()();
  IntColumn get chunkIndex => integer()();
  IntColumn get pageNumber => integer()();
  TextColumn get content => text()();
  TextColumn get embedding => text()(); // JSON array of floats
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Interface:**
```dart
class LocalVectorStore {
  Future<void> insertEmbedding(CachedEmbedding embedding);
  
  Future<List<CachedEmbedding>> searchSimilar(
    List<double> queryEmbedding,
    {int limit = 5, List<String>? fileIds}
  );
  
  Future<List<CachedEmbedding>> getUnsyncedEmbeddings();
  
  Future<void> markAsSynced(List<String> embeddingIds);
  
  Future<void> deleteByFileId(String fileId);
}
```

### 4. LocalLLMService (Flutter Service)

**Responsibilities:**
- Manage LLM model lifecycle
- Generate chat responses
- Handle streaming output

**Interface:**
```dart
class LocalLLMService {
  Future<void> loadModel(String modelName);
  
  Stream<String> generateResponse(
    List<ChatMessage> messages,
    {int maxTokens = 1000, double temperature = 0.7}
  );
  
  Future<void> unloadModel();
  
  Future<ModelInfo> getLoadedModel();
}
```

### 5. RAGService (Flutter Service - Enhanced)

**Responsibilities:**
- Orchestrate RAG pipeline (local or cloud)
- Retrieve relevant chunks
- Generate responses with citations

**Enhanced Interface:**
```dart
class RAGService {
  Future<RAGResponse> query(
    String question,
    {
      List<String>? selectedFileIds,
      int topK = 5,
      bool forceLocal = false,
      String? preferredProvider,
    }
  );
  
  // New: Offline RAG query
  Future<RAGResponse> queryOffline(
    String question,
    {List<String>? selectedFileIds, int topK = 5}
  );
  
  // New: Check if offline RAG is available
  Future<bool> isOfflineAvailable();
}
```

### 6. SyncService (Flutter Service)

**Responsibilities:**
- Sync embeddings to Pinecone
- Sync chat history to Supabase
- Handle conflict resolution
- Manage sync queue

**Interface:**
```dart
class SyncService {
  Future<void> syncAll();
  
  Future<void> syncEmbeddings();
  
  Future<void> syncChatHistory();
  
  Stream<SyncStatus> get syncStatus;
  
  Future<void> pauseSync();
  
  Future<void> resumeSync();
}
```

### 7. ModelManager (Flutter Service)

**Responsibilities:**
- Download and manage ML models
- Track model versions
- Manage storage

**Interface:**
```dart
class ModelManager {
  Future<List<AvailableModel>> getAvailableModels();
  
  Future<List<InstalledModel>> getInstalledModels();
  
  Future<void> downloadModel(
    String modelId,
    {void Function(double progress)? onProgress}
  );
  
  Future<void> deleteModel(String modelId);
  
  Future<int> getModelSize(String modelId);
  
  Future<int> getAvailableStorage();
}
```

## Data Models

### CachedEmbedding
```dart
class CachedEmbedding {
  final String id;
  final String fileId;
  final int chunkIndex;
  final int pageNumber;
  final String content;
  final List<double> embedding;
  final bool synced;
  final DateTime createdAt;
  final DateTime? syncedAt;
}
```

### LocalChatMessage
```dart
class LocalChatMessage {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<Citation>? citations;
  final bool generatedLocally;
  final bool synced;
  final DateTime createdAt;
  final DateTime? syncedAt;
}
```

### ModelInfo
```dart
class ModelInfo {
  final String id;
  final String name;
  final ModelType type; // embedding or llm
  final int sizeBytes;
  final int parameterCount;
  final String quantization; // Q4, Q8, etc.
  final List<String> supportedPlatforms;
  final bool isInstalled;
  final String? localPath;
}
```

### SearchResult
```dart
class SearchResult {
  final String fileId;
  final String fileName;
  final int pageNumber;
  final int chunkIndex;
  final String content;
  final double similarity;
}
```

### SyncStatus
```dart
class SyncStatus {
  final bool isSyncing;
  final int pendingEmbeddings;
  final int pendingMessages;
  final DateTime? lastSyncTime;
  final String? error;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Embedding Dimension Consistency
*For any* text input, when embeddings are generated locally or via cloud, the output vector SHALL have exactly 384 dimensions.
**Validates: Requirements 1.4, 11.1**

### Property 2: Platform-Appropriate Backend Selection
*For any* platform (Android, Windows, Web), when the System initializes ML models, it SHALL select the appropriate backend (ONNX Runtime + llama.cpp for native, Transformers.js + WebLLM for web) based on platform detection.
**Validates: Requirements 1.2, 1.3, 2.2, 2.3, 4.1, 4.2, 4.3, 4.4**

### Property 3: Offline Embedding Queue
*For any* embedding generated while offline, the embedding SHALL be stored in the local Drift database and added to the sync queue.
**Validates: Requirements 1.5, 6.1**

### Property 4: Automatic Sync on Connectivity
*For any* queued data (embeddings or chat messages), when the System detects online connectivity, it SHALL automatically initiate sync to cloud services (Pinecone/Supabase).
**Validates: Requirements 1.6, 6.2, 7.2**

### Property 5: Local-Only Offline Operations
*For any* AI operation (embedding generation, LLM inference, vector search) performed while offline, the operation SHALL complete without making network requests.
**Validates: Requirements 1.1, 2.5, 3.1, 3.4**

### Property 6: Quantized Model Format
*For any* local LLM model loaded by the System, the model SHALL be in quantized format (Q4 or Q8) to minimize memory usage.
**Validates: Requirements 2.4**

### Property 7: Dual Mode Support
*For any* AI operation when online, the System SHALL provide both local and cloud execution options to users.
**Validates: Requirements 2.1, 2.6**

### Property 8: Cosine Similarity Ranking
*For any* vector search operation (offline or online), retrieved chunks SHALL be ranked by cosine similarity score in descending order.
**Validates: Requirements 3.3, 11.4**

### Property 9: Offline Data Source
*For any* RAG query performed while offline, the System SHALL retrieve embeddings exclusively from the local Drift database without accessing Pinecone.
**Validates: Requirements 3.2**

### Property 10: WebGPU Fallback
*For any* web platform initialization, when WebGPU is unavailable, the System SHALL fallback to WASM backend for ML operations.
**Validates: Requirements 4.5**

### Property 11: Progress Reporting
*For any* model download operation, the System SHALL emit progress updates including bytes downloaded, total size, and download speed.
**Validates: Requirements 4.6, 5.2**

### Property 12: Graceful Degradation
*For any* platform lacking required ML capabilities, the System SHALL disable local AI features and operate in cloud-only mode without crashing.
**Validates: Requirements 4.7**

### Property 13: Model Deletion Frees Storage
*For any* installed model, when deleted by the user, the System SHALL remove model files and free the corresponding storage space.
**Validates: Requirements 5.4**

### Property 14: Preference Persistence
*For any* user preference (selected models, settings), when the System restarts, preferences SHALL be restored from persistent storage.
**Validates: Requirements 5.6, 9.5**

### Property 15: Storage Validation
*For any* model download request, when available storage is insufficient, the System SHALL display a warning before initiating download.
**Validates: Requirements 5.7**

### Property 16: Batch Sync Optimization
*For any* sync operation with multiple embeddings, the System SHALL batch embeddings into groups to minimize API calls to Pinecone.
**Validates: Requirements 6.3**

### Property 17: Last-Write-Wins Conflict Resolution
*For any* embedding or chat message conflict detected during sync, the System SHALL resolve using last-write-wins strategy based on timestamps.
**Validates: Requirements 6.4, 7.4**

### Property 18: Metadata Preservation
*For any* data synced to cloud (embeddings or chat messages), all metadata fields (file_id, chunk_index, page_number, timestamps, citations) SHALL be preserved.
**Validates: Requirements 6.5, 7.3**

### Property 19: Exponential Backoff Retry
*For any* failed sync operation, the System SHALL retry with exponentially increasing delays (1s, 2s, 4s, 8s, ...) up to a maximum retry count.
**Validates: Requirements 6.7, 7.7**

### Property 20: Connectivity-Based Data Source
*For any* chat history load operation, the System SHALL fetch from Supabase when online and from local Drift when offline.
**Validates: Requirements 7.5**

### Property 21: Lazy Model Loading
*For any* model initialization, the System SHALL defer loading model weights into memory until first use to minimize startup memory footprint.
**Validates: Requirements 8.1**

### Property 22: Idle Model Unloading
*For any* loaded model, when the System has been idle for the configured timeout period, the model SHALL be unloaded from memory.
**Validates: Requirements 8.2**

### Property 23: Low Memory Protection
*For any* low memory condition detected, the System SHALL automatically unload models and display a warning to users.
**Validates: Requirements 8.3**

### Property 24: Hardware Acceleration Usage
*For any* ML inference operation, when hardware acceleration (GPU, Neural Engine) is available, the System SHALL utilize it for improved performance.
**Validates: Requirements 8.4**

### Property 25: Streaming and Batching
*For any* large document processing operation, the System SHALL use streaming and batching techniques to prevent memory spikes.
**Validates: Requirements 8.6**

### Property 26: Model Information Completeness
*For any* model displayed in selection UI, the System SHALL show model size, memory requirements, and quality ratings.
**Validates: Requirements 9.3**

### Property 27: Dimension Change Re-indexing
*For any* model change that alters embedding dimensions, the System SHALL trigger re-indexing of all documents with the new model.
**Validates: Requirements 9.4**

### Property 28: Device-Appropriate Recommendations
*For any* model recommendation, the System SHALL suggest models compatible with detected device capabilities (memory, storage, compute).
**Validates: Requirements 9.6**

### Property 29: Configuration Change Warnings
*For any* model configuration change with storage or re-indexing implications, the System SHALL display warnings before applying changes.
**Validates: Requirements 9.7**

### Property 30: Status Indicator Updates
*For any* connectivity change or operation state change, the System SHALL update UI status indicators to reflect current state (online/offline, syncing, local/cloud).
**Validates: Requirements 10.1, 10.4, 10.5, 6.6**

### Property 31: Provider Display
*For any* online state, the System SHALL display all available AI providers (Local, OpenRouter, OpenAI, Claude, Gemini, Grok) in the selection UI.
**Validates: Requirements 10.3**

### Property 32: Error Message Clarity
*For any* operation failure (embedding generation, LLM inference, sync), the System SHALL provide clear error messages with actionable recovery options.
**Validates: Requirements 1.7, 2.7, 3.7, 10.7**

### Property 33: L2 Normalization Consistency
*For any* embedding generated, the System SHALL apply L2 normalization to ensure unit length vectors for consistent similarity calculations.
**Validates: Requirements 11.3**

### Property 34: Dimension Validation
*For any* embedding before storage, the System SHALL validate vector dimensions match expected size and reject invalid embeddings.
**Validates: Requirements 11.5**

### Property 35: Format Migration
*For any* embedding format change, the System SHALL automatically migrate existing embeddings to the new format without data loss.
**Validates: Requirements 11.7**

### Property 36: Non-Blocking Startup
*For any* app startup, the System SHALL allow full app functionality before models are downloaded, with AI features becoming available progressively.
**Validates: Requirements 12.1**

### Property 37: Background Downloads
*For any* model download, the System SHALL perform downloads in background threads without blocking UI interactions.
**Validates: Requirements 12.2**

### Property 38: Embedding Model Priority
*For any* initial model loading sequence, the System SHALL load embedding models before LLM models to enable document indexing first.
**Validates: Requirements 12.3**

### Property 39: Download Pause and Resume
*For any* model download, the System SHALL support pause and resume operations while preserving download progress.
**Validates: Requirements 12.4**

### Property 40: Checkpoint-Based Resume
*For any* interrupted download, when resumed, the System SHALL continue from the last saved checkpoint rather than restarting from beginning.
**Validates: Requirements 12.6**

### Property 41: Adaptive Download Strategy
*For any* model download under poor network conditions, the System SHALL adapt chunk sizes and retry strategies to prevent failures.
**Validates: Requirements 12.7**

## Error Handling

### Error Categories

1. **Model Loading Errors**
   - Model file not found
   - Corrupted model file
   - Insufficient memory
   - Unsupported platform

2. **Inference Errors**
   - Out of memory during inference
   - Model not loaded
   - Invalid input format
   - Timeout

3. **Sync Errors**
   - Network timeout
   - API rate limit exceeded
   - Authentication failure
   - Conflict resolution failure

4. **Storage Errors**
   - Insufficient disk space
   - Database corruption
   - Write permission denied

### Error Handling Strategy

**Graceful Degradation:**
- If local AI fails, fallback to cloud AI when online
- If sync fails, preserve local data and retry later
- If model loading fails, continue with cloud-only mode

**User Communication:**
- Clear error messages explaining what went wrong
- Actionable suggestions (e.g., "Free up 2GB storage to download model")
- Status indicators showing current capabilities

**Recovery Mechanisms:**
- Automatic retry with exponential backoff for transient failures
- Manual retry buttons for user-initiated recovery
- Model re-download option for corrupted files
- Database repair utilities for corruption

## Testing Strategy

### Unit Testing

**Component Tests:**
- LocalAIEngine: Test embedding generation, LLM inference, vector search
- EmbeddingService: Test local vs cloud orchestration, caching
- SyncService: Test queue management, batch uploads, conflict resolution
- ModelManager: Test download, storage, deletion

**Mock Dependencies:**
- Mock ONNX Runtime for testing without actual models
- Mock llama.cpp for testing LLM logic
- Mock network layer for testing offline/online transitions
- Mock Drift database for testing storage logic

### Property-Based Testing

The System will use property-based testing to verify correctness properties across random inputs:

**Framework:** 
- Dart: `test` package with custom property testing utilities
- Generate random text inputs, embeddings, chat messages
- Verify properties hold across 100+ iterations

**Key Properties to Test:**
- Embedding dimensions (Property 1)
- Offline operation isolation (Property 5)
- Cosine similarity ranking (Property 8)
- Conflict resolution (Property 17)
- Retry backoff timing (Property 19)

**Test Data Generation:**
- Random text strings (1-1000 characters)
- Random embeddings (384-dimensional vectors)
- Random file IDs and metadata
- Random network conditions (online/offline/poor)
- Random platform configurations

### Integration Testing

**End-to-End Flows:**
1. Document upload → Embedding generation → Local storage → Sync to Pinecone
2. Offline RAG query → Local vector search → Local LLM → Response with citations
3. Online RAG query → Pinecone search → Cloud LLM → Response with citations
4. Model download → Installation → First use → Unload → Reload

**Cross-Platform Testing:**
- Test on Android emulator and physical device
- Test on Windows desktop
- Test on Chrome/Edge/Firefox browsers
- Verify platform-specific backends work correctly

### Performance Testing

**Benchmarks:**
- Embedding generation speed (embeddings/second)
- LLM inference speed (tokens/second)
- Vector search latency (milliseconds)
- Sync throughput (embeddings/second)
- Memory usage during operations
- Battery drain during inference

**Targets:**
- Embedding generation: >10 embeddings/second
- LLM inference: >10 tokens/second
- Vector search: <100ms for 1000 vectors
- Memory usage: <500MB for 1B model, <2GB for 7B model

### Manual Testing

**User Scenarios:**
1. First-time user downloads models and indexes first document
2. User works offline for extended period, then syncs
3. User switches between devices mid-conversation
4. User runs out of storage during model download
5. User experiences poor network during sync

## Implementation Notes

### Model Selection Rationale

**Embedding Models:**
- **sentence-transformers/all-MiniLM-L6-v2** (Default): 384 dimensions, 80MB, good quality/size tradeoff
- **sentence-transformers/all-MiniLM-L12-v2**: 384 dimensions, 120MB, better quality
- **BAAI/bge-small-en-v1.5**: 384 dimensions, 130MB, state-of-the-art quality

**LLM Models:**
- **Phi-3-mini-4k-instruct-q4** (Default): 1.8B params, 1.2GB, fast and efficient
- **Llama-3.2-1B-Instruct-q4**: 1B params, 800MB, smallest option
- **Llama-3.2-3B-Instruct-q4**: 3B params, 2GB, better quality
- **Qwen2-1.5B-Instruct-q4**: 1.5B params, 1GB, multilingual support

### Platform-Specific Considerations

**Android:**
- Use ONNX Runtime with NNAPI delegate for hardware acceleration
- Store models in app's internal storage
- Request WAKE_LOCK permission for long-running inference
- Monitor battery level and adjust model usage

**Windows:**
- Use ONNX Runtime with DirectML for GPU acceleration
- Store models in AppData/Local
- Use Windows ML APIs when available
- Support both x64 and ARM64 architectures

**Web (PWA):**
- Use WebGPU when available (Chrome 113+, Edge 113+)
- Fallback to WASM for older browsers
- Store models in IndexedDB or Cache API
- Use Web Workers for non-blocking inference
- Implement service worker for offline functionality

### Security Considerations

1. **Model Integrity**: Verify model checksums before loading
2. **Sandboxing**: Run inference in isolated contexts (Web Workers, separate threads)
3. **Data Privacy**: All local inference happens on-device, no data sent to servers
4. **Secure Storage**: Encrypt sensitive model metadata in local storage
5. **API Key Protection**: Never expose API keys in client-side code

### Migration Strategy

**Phase 1: Foundation (Weeks 1-2)**
- Implement LocalAIEngine interfaces
- Add Drift schema for embeddings and chat
- Create ModelManager for downloads

**Phase 2: Embedding Pipeline (Weeks 3-4)**
- Implement local embedding generation
- Add embedding sync to Pinecone
- Test offline document indexing

**Phase 3: LLM Integration (Weeks 5-6)**
- Implement local LLM inference
- Add offline RAG query pipeline
- Test offline chat functionality

**Phase 4: Sync and Polish (Weeks 7-8)**
- Implement chat history sync
- Add conflict resolution
- Polish UI indicators and error handling
- Performance optimization

### Future Enhancements

1. **On-Device Fine-Tuning**: Allow users to fine-tune models on their documents
2. **Model Compression**: Implement dynamic quantization for further size reduction
3. **Federated Learning**: Share model improvements across users while preserving privacy
4. **Multi-Modal Support**: Add support for image and audio embeddings
5. **Custom Model Import**: Allow users to import their own ONNX/GGUF models
