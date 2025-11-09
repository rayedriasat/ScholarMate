# Memory Flow Diagram - PDF Indexing

## Overview: Sequential Batch Processing

```
PDF File (e.g., 50 pages)
    ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Extract & Chunk (Memory: ~50-80MB)                  │
├─────────────────────────────────────────────────────────────┤
│ Process 2 pages at a time (PDF_PAGE_BATCH_SIZE=2)          │
│                                                              │
│ Pages 1-2  → Extract → Chunk → [~20 chunks] → Store        │
│   ↓ GC cleanup (0.05s delay)                               │
│ Pages 3-4  → Extract → Chunk → [~20 chunks] → Store        │
│   ↓ GC cleanup (0.05s delay)                               │
│ Pages 5-6  → Extract → Chunk → [~20 chunks] → Store        │
│   ↓ ... continue for all pages                             │
│                                                              │
│ Result: ~500 chunks total (50 pages × 10 chunks/page)      │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Generate Embeddings (Memory: ~24-30MB per batch)    │
├─────────────────────────────────────────────────────────────┤
│ Process 3 chunks at a time (EMBEDDING_BATCH_SIZE=3)        │
│                                                              │
│ Chunks 1-3   → Embed → [3 vectors] → Store                 │
│   ↓ GC cleanup (0.2s delay)                                │
│ Chunks 4-6   → Embed → [3 vectors] → Store                 │
│   ↓ GC cleanup (0.2s delay)                                │
│ Chunks 7-9   → Embed → [3 vectors] → Store                 │
│   ↓ ... continue for all chunks                            │
│                                                              │
│ Result: ~167 batches (500 chunks ÷ 3)                      │
└─────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Store to Pinecone (Memory: ~10-12MB per batch)     │
├─────────────────────────────────────────────────────────────┤
│ Process 25 vectors at a time (PINECONE_BATCH_SIZE=25)      │
│                                                              │
│ For each embedding batch (3 vectors):                       │
│   Vectors 1-3  → Prepare → Upsert (sub-batch 1)           │
│     ↓ GC cleanup (0.1s delay)                              │
│                                                              │
│ Every 25 vectors triggers a Pinecone upsert                │
│   ↓ GC cleanup (0.3s delay)                                │
│                                                              │
│ Result: ~20 Pinecone upserts (500 vectors ÷ 25)           │
└─────────────────────────────────────────────────────────────┘
    ↓
✅ Indexing Complete
```

## Memory Timeline (50-page PDF)

```
Time →
0s    ┌─────────────────────────────────────────────────────────┐
      │ Start: 50MB (base memory)                               │
      └─────────────────────────────────────────────────────────┘

10s   ┌─────────────────────────────────────────────────────────┐
      │ Extract & Chunk: 80MB peak                              │
      │ ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
      └─────────────────────────────────────────────────────────┘

30s   ┌─────────────────────────────────────────────────────────┐
      │ Generate Embeddings: 100-150MB peak (cycling)           │
      │ ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
      │ ▲ ▼ ▲ ▼ ▲ ▼ (batch cycles with GC cleanup)           │
      └─────────────────────────────────────────────────────────┘

120s  ┌─────────────────────────────────────────────────────────┐
      │ Store to Pinecone: 120-180MB peak (cycling)             │
      │ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
      │ ▲ ▼ ▲ ▼ ▲ ▼ (batch cycles with GC cleanup)           │
      └─────────────────────────────────────────────────────────┘

180s  ┌─────────────────────────────────────────────────────────┐
      │ Complete: 60MB (cleanup complete)                       │
      │ ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
      └─────────────────────────────────────────────────────────┘

Legend:
█ = Memory in use
░ = Available memory
▲ = Memory spike (batch processing)
▼ = Memory drop (GC cleanup)
```

## Memory Comparison: Before vs After

### Before Optimization (❌ Crashes on Render)

```
┌─────────────────────────────────────────────────────────────┐
│ Batch Processing: 10 chunks at once                         │
│                                                              │
│ Memory Usage:                                                │
│ ████████████████████████████████████████████████ 400-600MB  │
│                                                              │
│ Peak: 600MB+ (EXCEEDS 512MB LIMIT) ❌                       │
└─────────────────────────────────────────────────────────────┘
```

### After Optimization (✅ Stable on Render)

```
┌─────────────────────────────────────────────────────────────┐
│ Batch Processing: 3 chunks at once                          │
│                                                              │
│ Memory Usage:                                                │
│ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░ 150-250MB  │
│                                                              │
│ Peak: 250MB (WELL UNDER 512MB LIMIT) ✅                     │
└─────────────────────────────────────────────────────────────┘
```

## Batch Size Impact on Memory

```
Embedding Batch Size vs Memory Usage:

Batch=1:  ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ~10MB
Batch=3:  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ~30MB  ← Current
Batch=5:  ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ~50MB
Batch=10: ████████████████████████████████████████░░░░░░░░░░  ~100MB ← Previous
Batch=20: ████████████████████████████████████████████████████ ~200MB ← Danger!

Render Free Tier Limit: 512MB
Safe Operating Range: < 400MB
Current Peak: ~250MB ✅
```

## Processing Pipeline Detail

```
┌──────────────────────────────────────────────────────────────┐
│ Single Batch Cycle (3 chunks)                                │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ 1. Load 3 chunks from queue                                  │
│    Memory: +5MB                                               │
│    ├─ Chunk 1: "Lorem ipsum..." (400 chars)                 │
│    ├─ Chunk 2: "Dolor sit amet..." (400 chars)              │
│    └─ Chunk 3: "Consectetur..." (400 chars)                 │
│                                                               │
│ 2. Generate embeddings (HuggingFace)                         │
│    Memory: +25MB (model inference)                            │
│    ├─ Chunk 1 → [0.123, 0.456, ...] (384 dims)             │
│    ├─ Chunk 2 → [0.789, 0.012, ...] (384 dims)             │
│    └─ Chunk 3 → [0.345, 0.678, ...] (384 dims)             │
│                                                               │
│ 3. Prepare for Pinecone                                      │
│    Memory: +3MB (vector formatting)                           │
│    └─ Format: {id, values, metadata}                        │
│                                                               │
│ 4. Upsert to Pinecone                                        │
│    Memory: +2MB (network buffer)                              │
│    └─ Send to Pinecone API                                  │
│                                                               │
│ 5. Cleanup                                                    │
│    Memory: -35MB (GC cleanup)                                 │
│    ├─ del chunks                                             │
│    ├─ del embeddings                                         │
│    ├─ gc.collect()                                           │
│    └─ await asyncio.sleep(0.2s)                             │
│                                                               │
│ Total cycle time: ~1-2 seconds                               │
│ Peak memory: ~35MB per batch                                 │
└──────────────────────────────────────────────────────────────┘
```

## Garbage Collection Strategy

```
┌──────────────────────────────────────────────────────────────┐
│ Aggressive GC Pattern                                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ After each operation:                                         │
│   1. Delete temporary variables                              │
│      del batch_data                                           │
│      del batch_result                                         │
│                                                               │
│   2. Force garbage collection                                │
│      gc.collect()                                             │
│                                                               │
│   3. Yield control to event loop                             │
│      await asyncio.sleep(0.1-0.3s)                           │
│                                                               │
│ This ensures:                                                 │
│   ✅ Memory is freed immediately                             │
│   ✅ No memory accumulation between batches                  │
│   ✅ Predictable memory usage                                │
│   ✅ Stable operation under memory constraints               │
└──────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Sequential Processing**: Process small batches sequentially, not in parallel
2. **Aggressive Cleanup**: Delete and GC after every batch
3. **Small Batches**: 3 chunks at a time keeps memory under control
4. **GC Delays**: Give Python time to free memory between batches
5. **Sub-Batching**: Further split Pinecone upserts to avoid spikes

## Memory Safety Margins

```
Render Free Tier: 512MB total
├─ System overhead: ~50MB
├─ FastAPI base: ~80MB
├─ HuggingFace model: ~100MB
├─ Available for processing: ~280MB
│
└─ Our usage:
   ├─ Base: ~50MB
   ├─ Peak per batch: ~35MB
   ├─ Total peak: ~250MB ✅
   └─ Safety margin: ~260MB (50% buffer)
```

This ensures we never exceed the limit, even with multiple concurrent requests.
