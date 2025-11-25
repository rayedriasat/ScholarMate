# Design Document — Offline RAG

## Overview

This design extends ScholarMate with offline AI capabilities using local LLM inference and embedding generation. The architecture prioritizes simplicity, cross-platform compatibility, and minimal dependencies. The system uses flutter_llama (wrapping llama.cpp) for LLM inference and onnxruntime for embedding generation, with automatic fallback between cloud and local processing based on connectivity.

### Key Design Decisions

1. **flutter_llama for LLM**: Mature, production-ready plugin with GPU acceleration (Metal/Vulkan), supports Android/iOS/macOS
2. **ONNX Runtime for Embeddings**: Cross-platform (Android/iOS/Windows/macOS/Linux), efficient, supports sentence-transformers models
3. **Drift for Vector Storage**: Already in use, works on all platforms including web, simple cosine similarity search
4. **Quantized Models**: Q4_K_M quantization for 4x smaller size with minimal quality loss
5. **Hybrid Architecture**: Seamless switching between cloud (GROQ) and local models based on connectivity
6. **Web via WASM**: llama.cpp WASM build + onnxruntime-web for browser support

### Model Selection (MVP)

**LLM Models:**
- Mobile/Android: Gemma-2B-instruct Q4_K_M (~800MB, 15-25 tokens/sec on mid-range phones)
- Desktop: Gemma-2B-instruct Q5_K_M (~1.5GB, 30-50 tokens/sec)
- Web/PWA: TinyLlama-1.1B Q4_K_M (~600MB, 10-20 tokens/sec in browser)

**Embedding Models:**
- All platforms: all-MiniLM-L6-v2 ONNX (~80MB, 384 dimensions, fast inference)

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Model       │  │  Local LLM   │  │   Local      │     │
│  │  Manager     │  │  Service     │  │  Embeddings  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Offline     │  │  Hybrid RAG  │  │    Chat      │     │
│  │  Vector DB   │  │  Orchestrator│  │   History    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Conditional (online only)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Services                           │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │     GROQ     │  │   Supabase   │                        │
│  │   (Online)   │  │  (Chat Sync) │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### Platform-Specific Implementation

**Android/iOS/macOS:**
- flutter_llama plugin (native llama.cpp bindings)
- GPU acceleration: Metal (iOS/macOS), Vulkan (Android)
- onnxruntime plugin for embeddings
- Models stored in app documents directory

**Windows/Linux:**
- flutter_llama plugin (native llama.cpp bindings)
- CPU inference with multi-threading
- onnxruntime plugin for embeddings
- Models stored in app data directory

**Web/PWA:**
- llama.cpp WASM build loaded via JS interop
- onnxruntime-web for embeddings
- Models stored in IndexedDB
- Web Workers for non-blocking inference

## Components and Interfaces

### 1. Model Manager Service

```dart
class ModelManagerService {
  // Model discovery and download
  Future<List<AvailableModel>> getAvailableModels();
  Future<void> downloadModel(String modelId, {
    Function(double progress)? onProgress
  });
  Future<void> deleteModel(String modelId);
  Future<void> verifyModelIntegrity(String modelId);
  
  // Model metadata
  Future<List<LocalModel>> getInstalledModels();
  Future<ModelInfo> getModelInfo(String modelId);
  Future<DeviceCapabilities> detectDeviceCapabilities();
  Future<List<ModelRecommendation>> getRecommendedModels();
  
  // Storage management
  Future<int> getModelsStorageSize();
  Future<void> clearModelCache();
}

class AvailableModel {
  final String id;
  final String name;
  final String type; // 'llm' or 'embedding'
  final int sizeBytes;
  final String quantization; // 'Q4_K_M', 'Q5_K_M', etc.
  final String downloadUrl;
  final String checksum;
  final Map<String, dynamic> capabilities;
}

class LocalModel {
  final String id;
  final String path;
  final String type;
  final int sizeBytes;
  final DateTime installedAt;
  final bool isLoaded;
}

class DeviceCapabilities {
  final int ramMB;
  final int availableStorageMB;
  final bool hasGPU;
  final String gpuType; // 'metal', 'vulkan', 'opencl', 'none'
  final String platform; // 'android', 'ios', 'windows', 'web'
}
```

### 2. Local LLM Service

```dart
class LocalLLMService {
  // Model lifecycle
  Future<bool> loadModel(String modelPath, {
    int nThreads = 4,
    int nGpuLayers = -1, // -1 = all layers on GPU
    int contextSize = 2048,
    bool useGpu = true,
  });
  Future<void> unloadModel();
  bool isModelLoaded();
  
  // Inference
  Stream<String> generateStream(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    List<String>? stopSequences,
  });
  
  Future<String> generate(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
  });
  
  // Performance monitoring
  Future<InferenceStats> getStats();
  Future<void> cancelGeneration();
}

class InferenceStats {
  final double tokensPerSecond;
  final int totalTokens;
  final int promptTokens;
  final int completionTokens;
  final Duration inferenceTime;
  final int memoryUsageMB;
}
```

### 3. Local Embeddings Service

```dart
class LocalEmbeddingsService {
  // Model lifecycle
  Future<bool> loadModel(String modelPath);
  Future<void> unloadModel();
  bool isModelLoaded();
  
  // Embedding generation
  Future<List<double>> generateEmbedding(String text);
  Future<List<List<double>>> generateEmbeddings(
    List<String> texts, {
    int batchSize = 5,
    Function(int processed, int total)? onProgress,
  });
  
  // Runs in isolate to prevent UI jank
  Future<List<List<double>>> generateEmbeddingsInBackground(
    List<String> texts
  );
  
  // Utilities
  int getEmbeddingDimension();
  Future<EmbeddingStats> getStats();
}

class EmbeddingStats {
  final int embeddingsGenerated;
  final Duration averageTime;
  final int memoryUsageMB;
}
```

### 4. Offline Vector Store Service

```dart
class OfflineVectorStoreService {
  // Document indexing
  Future<void> indexDocument(
    String fileId,
    List<DocumentChunk> chunks,
    List<List<double>> embeddings,
  );
  
  Future<void> deleteDocumentIndex(String fileId);
  Future<bool> isDocumentIndexed(String fileId);
  
  // Vector search
  Future<List<SearchResult>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    List<String>? fileIds, // Filter by source files
    double minScore = 0.0,
  });
  
  // Cosine similarity calculation
  double cosineSimilarity(List<double> a, List<double> b);
  
  // Statistics
  Future<VectorStoreStats> getStats();
  Future<void> clearIndex();
}

class DocumentChunk {
  final String chunkId;
  final String fileId;
  final String fileName;
  final int pageNumber;
  final int chunkIndex;
  final String content;
  final Map<String, dynamic> metadata;
}

class SearchResult {
  final String chunkId;
  final String fileId;
  final String fileName;
  final int pageNumber;
  final String content;
  final double score;
  final Map<String, dynamic> metadata;
}

class VectorStoreStats {
  final int totalDocuments;
  final int totalChunks;
  final int totalEmbeddings;
  final int storageSizeMB;
}
```

### 5. Hybrid RAG Orchestrator

```dart
class HybridRAGOrchestrator {
  // Main RAG query interface
  Future<RAGResponse> query(
    String question, {
    List<String>? selectedFileIds,
    bool forceOffline = false,
  });
  
  // Mode detection and switching
  Future<RAGMode> getCurrentMode();
  Future<bool> isOnline();
  Future<void> setForceOfflineMode(bool enabled);
  
  // Internal routing
  Future<RAGResponse> _queryOnline(String question, List<String>? fileIds);
  Future<RAGResponse> _queryOffline(String question, List<String>? fileIds);
  
  // Context retrieval
  Future<List<SearchResult>> retrieveContext(
    String question,
    List<String>? fileIds,
    bool useLocal,
  );
  
  // Response generation
  Future<String> generateResponse(
    String question,
    List<SearchResult> context,
    bool useLocal,
  );
}

enum RAGMode {
  online,  // Using GROQ API
  offline, // Using local models
  hybrid,  // Automatic switching
}

class RAGResponse {
  final String answer;
  final List<Citation> citations;
  final RAGMode modeUsed;
  final InferenceStats? stats;
  final DateTime timestamp;
}

class Citation {
  final String fileId;
  final String fileName;
  final int pageNumber;
  final String snippet;
  final double relevanceScore;
}
```

### 6. Chat History Service

```dart
class ChatHistoryService {
  // Local storage
  Future<void> saveChatMessage(ChatMessage message);
  Future<List<ChatMessage>> getChatHistory({
    int limit = 50,
    DateTime? before,
  });
  Future<void> deleteChatMessage(String messageId);
  Future<void> clearChatHistory();
  
  // Sync with Supabase
  Future<void> syncChatHistory();
  Future<void> uploadPendingMessages();
  Future<void> downloadRemoteMessages();
  Future<void> resolveConflicts(List<ChatMessage> conflicts);
  
  // Search
  Future<List<ChatMessage>> searchChatHistory(String query);
}

class ChatMessage {
  final String id;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<Citation>? citations;
  final DateTime timestamp;
  final String modelUsed; // 'groq', 'gemma-2b', 'tinyllama', etc.
  final RAGMode mode;
  final String syncStatus; // 'synced', 'pending', 'failed'
}
```

## Data Models

### Drift Database Schema Extensions

```sql
-- Local models table
CREATE TABLE local_models (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'llm' or 'embedding'
    path TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    quantization TEXT,
    checksum TEXT,
    installed_at INTEGER NOT NULL,
    last_used_at INTEGER,
    is_loaded INTEGER DEFAULT 0
);

-- Vector embeddings table
CREATE TABLE vector_embeddings (
    id TEXT PRIMARY KEY,
    chunk_id TEXT NOT NULL,
    file_id TEXT NOT NULL,
    embedding BLOB NOT NULL, -- Serialized float array
    dimension INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
);

-- Document chunks table
CREATE TABLE document_chunks (
    chunk_id TEXT PRIMARY KEY,
    file_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    page_number INTEGER NOT NULL,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    char_start INTEGER,
    char_end INTEGER,
    metadata TEXT, -- JSON
    created_at INTEGER NOT NULL,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
);

-- Chat messages table (local)
CREATE TABLE chat_messages (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    citations TEXT, -- JSON array
    timestamp INTEGER NOT NULL,
    model_used TEXT NOT NULL,
    mode TEXT NOT NULL,
    sync_status TEXT DEFAULT 'pending',
    synced_at INTEGER
);

-- Model download queue
CREATE TABLE model_downloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_id TEXT NOT NULL,
    download_url TEXT NOT NULL,
    total_bytes INTEGER NOT NULL,
    downloaded_bytes INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending', -- 'pending', 'downloading', 'completed', 'failed'
    error_message TEXT,
    created_at INTEGER NOT NULL,
    completed_at INTEGER
);

-- Indexes for performance
CREATE INDEX idx_vector_embeddings_file_id ON vector_embeddings(file_id);
CREATE INDEX idx_document_chunks_file_id ON document_chunks(file_id);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_timestamp ON chat_messages(timestamp);
CREATE INDEX idx_chat_messages_sync_status ON chat_messages(sync_status);
```

### Supabase Schema Extensions

```sql
-- Chat messages table (cloud sync)
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_id TEXT UNIQUE NOT NULL, -- Client-generated ID for deduplication
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    citations JSONB,
    timestamp TIMESTAMPTZ NOT NULL,
    model_used TEXT NOT NULL,
    mode TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_timestamp ON chat_messages(timestamp);
CREATE INDEX idx_chat_messages_message_id ON chat_messages(message_id);

-- RLS Policy
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY chat_messages_policy ON chat_messages FOR ALL 
USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, I identified several areas where properties can be consolidated:

**Redundancy Elimination:**
1. Properties 2.3 and 4.2 (offline routing for chat and embeddings) can be combined into a single "offline mode routing" property
2. Properties 5.1 and 5.2 (online/offline routing) are the inverse of each other and can be combined
3. Properties 7.1, 7.2, and 7.3 (chat storage and sync) can be consolidated into a comprehensive sync property
4. Properties 1.2 and 1.6 (download and delete) are inverse operations that can be tested together as a round-trip property

**Final Property Set:**
After consolidation, we have 25 unique properties that provide comprehensive coverage without redundancy.

### Core Properties

**Property 1: Model download integrity**
*For any* model downloaded, verifying the checksum should match the expected value from the model metadata
**Validates: Requirements 1.5**

**Property 2: Model storage round-trip**
*For any* model, downloading then deleting should restore the original storage state
**Validates: Requirements 1.2, 1.6**

**Property 3: Download progress monotonicity**
*For any* model download in progress, progress updates should be monotonically increasing until completion
**Validates: Requirements 1.4**

**Property 4: Model recommendations match device capabilities**
*For any* device capabilities, recommended models should fit within available RAM and storage constraints
**Validates: Requirements 1.7, 9.2**

**Property 5: GPU acceleration when available**
*For any* device with GPU support, loading a model should enable GPU layers
**Validates: Requirements 2.2**

**Property 6: Offline mode uses local models**
*For any* request made while offline, the system should use local LLM and local embeddings, never cloud APIs
**Validates: Requirements 2.3, 4.2, 5.2**

**Property 7: Online mode uses cloud models**
*For any* request made while online (and not in forced offline mode), the system should use GROQ API
**Validates: Requirements 5.1**

**Property 8: Token streaming**
*For any* LLM generation, tokens should arrive incrementally in the stream, not all at once
**Validates: Requirements 2.4**

**Property 9: Context window limit**
*For any* prompt sent to local LLM, the total context size should never exceed 2048 tokens
**Validates: Requirements 2.5**

**Property 10: Document chunking consistency**
*For any* document, chunks should be approximately 400 characters with 40-character overlap between consecutive chunks
**Validates: Requirements 3.3**

**Property 11: Embedding storage round-trip**
*For any* generated embedding, storing then retrieving it should return an equivalent vector
**Validates: Requirements 3.4**

**Property 12: Background processing isolation**
*For any* embedding generation task, it should execute in a background isolate, not the main UI thread
**Validates: Requirements 3.5**

**Property 13: Cosine similarity bounds**
*For any* two embeddings, cosine similarity should be between -1.0 and 1.0 inclusive
**Validates: Requirements 4.1**

**Property 14: Top-K retrieval**
*For any* search query, the number of results should be min(K, total_chunks) where K=5
**Validates: Requirements 4.3**

**Property 15: Source file filtering**
*For any* search query with file filters, all returned results should have file_id in the selected file list
**Validates: Requirements 4.4**

**Property 16: Search result completeness**
*For any* search result, it should contain file_id, file_name, page_number, content, and relevance_score fields
**Validates: Requirements 4.5**

**Property 17: Forced offline mode**
*For any* request when forced offline mode is enabled, local models should be used even if connectivity is available
**Validates: Requirements 5.5**

**Property 18: Citation format consistency**
*For any* RAG response, citations should have the same structure (file_id, file_name, page_number, snippet) regardless of whether generated online or offline
**Validates: Requirements 5.6**

**Property 19: Web model size limits**
*For any* model recommended on web platform, the size should be less than 1GB
**Validates: Requirements 6.5**

**Property 20: Web worker execution**
*For any* inference on web platform, it should execute in a Web Worker, not the main thread
**Validates: Requirements 6.6**

**Property 21: IndexedDB storage on web**
*For any* model downloaded on web platform, it should be stored in IndexedDB and retrievable offline
**Validates: Requirements 6.3**

**Property 22: Chat message sync completeness**
*For any* chat message synced to Supabase, it should include content, citations, timestamp, model_used, and mode fields
**Validates: Requirements 7.1, 7.2, 7.3**

**Property 23: Cross-device chat sync**
*For any* chat message created on device A, after sync it should appear on device B with identical content
**Validates: Requirements 7.4**

**Property 24: Conflict resolution by timestamp**
*For any* two conflicting chat messages, the one with the later timestamp should be preserved
**Validates: Requirements 7.5**

**Property 25: Chat deletion propagation**
*For any* chat message deleted locally, after sync it should also be deleted from Supabase
**Validates: Requirements 7.6**

**Property 26: Concurrent embedding limit**
*For any* point during embedding generation, the number of concurrent tasks should not exceed 5
**Validates: Requirements 8.1**

**Property 27: Quantized model usage**
*For any* loaded model, it should use Q4_K_M or Q5_K_M quantization
**Validates: Requirements 8.2**

**Property 28: Model auto-unload**
*For any* loaded model, if no inference occurs for 5 minutes, the model should be automatically unloaded
**Validates: Requirements 8.3**

**Property 29: Low-power mode parameter adjustment**
*For any* inference in low-power mode, temperature should be reduced and max_tokens should be limited
**Validates: Requirements 8.6**

**Property 30: Model size warning**
*For any* model selection where model size exceeds available device RAM, a warning should be displayed
**Validates: Requirements 9.3**

**Property 31: Failed embedding retry queue**
*For any* embedding generation that fails, the document should be added to a retry queue
**Validates: Requirements 10.3**

**Property 32: AI error logging**
*For any* AI operation error, a log entry should be created in local storage
**Validates: Requirements 10.4**

**Property 33: Reset clears all AI data**
*For any* AI reset operation, all local models and cache should be deleted
**Validates: Requirements 10.5**

**Property 34: Graceful degradation**
*For any* AI component failure, non-AI features (PDF viewing, annotations, file management) should continue functioning
**Validates: Requirements 10.6**

## Error Handling

### Model Loading Errors
- **Out of Memory**: Cancel load, suggest smaller quantization (Q4 instead of Q5)
- **Corrupted Model**: Delete and re-download with integrity check
- **Unsupported Platform**: Fallback to cloud mode, disable local AI features
- **GPU Initialization Failure**: Fallback to CPU inference with warning

### Inference Errors
- **Context Too Long**: Truncate to 2048 tokens, warn user
- **Generation Timeout**: Cancel after 60 seconds, allow retry
- **Out of Memory During Inference**: Unload model, suggest restart or smaller model
- **Invalid Input**: Sanitize and retry, or return error message

### Embedding Errors
- **Batch Processing Failure**: Retry individual chunks, log failures
- **ONNX Runtime Error**: Fallback to cloud embeddings if online
- **Storage Full**: Pause indexing, prompt user to free space
- **Corrupted Embedding Model**: Re-download model

### Sync Errors
- **Network Timeout**: Queue for retry with exponential backoff
- **Conflict Resolution Failure**: Log conflict, preserve both versions
- **Supabase Connection Error**: Continue offline, retry on next connectivity check
- **Authentication Expired**: Refresh tokens, retry sync

### Graceful Degradation Strategy
1. AI features fail → Continue with non-AI features (PDF viewing, annotations)
2. Local models fail → Fallback to cloud models if online
3. Cloud models fail → Use local models if available
4. Both fail → Disable AI features, show clear error message

## Testing Strategy

### Unit Testing
- Model download and verification logic
- Chunking algorithm with various document sizes
- Cosine similarity calculation accuracy
- Sync conflict resolution logic
- Platform-specific model loading (mock native plugins)

### Property-Based Testing
- Use `test` package with custom generators for property tests
- Generate random documents, embeddings, and queries
- Test properties across wide input space (100+ iterations per property)
- Focus on invariants, round-trips, and consistency properties

**Property Test Framework:**
```dart
// Example property test structure
import 'package:test/test.dart';

void main() {
  group('Offline RAG Properties', () {
    test('Property 1: Model download integrity', () {
      // Feature: offline-rag, Property 1: Model download integrity
      // Generate random model metadata
      // Download model
      // Verify checksum matches
    });
    
    test('Property 10: Document chunking consistency', () {
      // Feature: offline-rag, Property 10: Document chunking consistency
      // Generate random documents of various sizes
      // Chunk each document
      // Verify chunk sizes ~400 chars with 40 char overlap
    });
  });
}
```

### Integration Testing
- End-to-end offline RAG flow: upload PDF → index → query → get response
- Cross-platform model loading (Android, Windows, Web)
- Online/offline mode switching
- Chat history sync across devices

### Performance Testing
- Measure inference speed on target devices
- Monitor memory usage during embedding generation
- Test with large document libraries (100+ PDFs)
- Verify UI responsiveness during background processing

### Platform-Specific Testing
- **Android**: Test on low-end devices (2GB RAM), verify Vulkan GPU acceleration
- **Windows**: Test CPU inference with multi-threading
- **Web**: Test WASM performance, IndexedDB storage limits, Web Worker execution

## Implementation Notes

### Model Selection Rationale
- **Gemma-2B**: Lightweight Google model, good quality/size ratio, 2B params, fits mobile constraints
- **TinyLlama**: Smallest viable model for web, 1.1B params, acceptable quality
- **all-MiniLM-L6-v2**: Fast embedding model, 384 dims, good semantic understanding

### Quantization Strategy
- Q4_K_M: 4-bit quantization, ~4x smaller, minimal quality loss (<5%)
- Q5_K_M: 5-bit quantization, ~3x smaller, negligible quality loss (<2%)
- Avoid Q2/Q3: Too much quality degradation for general use

### Memory Management
- Unload models after inactivity to free RAM
- Process embeddings in small batches (5 chunks)
- Use isolates/workers to prevent main thread blocking
- Monitor memory usage, warn at 80% capacity

### Storage Optimization
- Store embeddings as compressed BLOB (float32 → uint8 quantization)
- Implement LRU cache for frequently accessed chunks
- Periodic cleanup of orphaned embeddings
- Limit chat history to last 1000 messages locally

### Web Platform Considerations
- WASM models load slowly (~10-30 seconds for TinyLlama)
- IndexedDB has ~50MB-1GB limits depending on browser
- Web Workers required for non-blocking inference
- Consider showing loading screen during model initialization

## Security Considerations

### Model Integrity
- Verify checksums for all downloaded models
- Use HTTPS for model downloads
- Reject models with invalid signatures

### Data Privacy
- All local inference happens on-device, no data sent to cloud
- Forced offline mode for sensitive documents
- Clear all AI data on logout
- Encrypt local model cache on mobile platforms

### Resource Limits
- Prevent DoS via excessive embedding generation
- Rate limit model downloads
- Cap maximum model size per platform
- Monitor and limit memory usage

## Deployment Considerations

### Model Hosting
- Host GGUF and ONNX models on CDN (e.g., Cloudflare R2, free tier)
- Provide model catalog JSON with metadata and download URLs
- Implement versioning for model updates
- Support resume for interrupted downloads

### Progressive Enhancement
- Ship app without bundled models (smaller initial download)
- Prompt user to download models on first AI feature use
- Allow app to function fully without local models (cloud-only mode)
- Provide "offline pack" download option in settings

### Platform-Specific Builds
- Android: Include Vulkan support, optimize for ARM
- Windows: Include CPU-optimized builds
- Web: Lazy-load WASM modules, use CDN for models
- iOS/macOS: Include Metal acceleration (future work)

### Monitoring and Analytics
- Track model download success rates
- Monitor inference performance metrics
- Log error rates by platform
- Measure online vs offline usage patterns

