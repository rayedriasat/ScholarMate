# Memory Settings Quick Reference

## Current Settings (Render Free Tier - 512MB)

```bash
# Chunk Configuration
chunk_size=400              # Characters per chunk
chunk_overlap=40            # Character overlap

# Batch Sizes
EMBEDDING_BATCH_SIZE=3      # Chunks to embed at once
PDF_PAGE_BATCH_SIZE=2       # PDF pages to process at once
PINECONE_BATCH_SIZE=25      # Vectors to upsert at once

# GC Delays
extract_and_chunk: 0.05s    # After page batch
generate_embeddings: 0.2s   # After embedding batch
store_embeddings: 0.3s      # After storage batch
pinecone_sub_batch: 0.1s    # After Pinecone upsert
```

## Memory Usage Per Batch

| Operation | Memory | Notes |
|-----------|--------|-------|
| Embedding (3 chunks) | ~24-30MB | HuggingFace model |
| Pinecone upsert (25 vectors) | ~10-12MB | Vector preparation |
| Peak per cycle | ~40-50MB | Total per batch |
| Typical PDF (50 pages) | ~150-250MB | Peak during processing |

## Adjustment Guide

### If Memory Exceeds 450MB

**Option 1: Reduce batch sizes**
```bash
EMBEDDING_BATCH_SIZE=2
PDF_PAGE_BATCH_SIZE=1
PINECONE_BATCH_SIZE=10
```

**Option 2: Reduce chunk size**
```python
chunk_size=300
chunk_overlap=30
```

**Option 3: Increase GC delays**
```python
await asyncio.sleep(0.5)  # Everywhere
```

### If Processing Too Slow

**Option 1: Increase batch sizes (monitor memory!)**
```bash
EMBEDDING_BATCH_SIZE=5
PDF_PAGE_BATCH_SIZE=3
PINECONE_BATCH_SIZE=50
```

**Option 2: Upgrade Render plan**
- Starter: $7/month → 1GB RAM
- Standard: $25/month → 2GB RAM

## Processing Speed Estimates

| PDF Size | Time (Current) | Time (Optimized) | Memory Peak |
|----------|----------------|------------------|-------------|
| 10 pages | 30-60s | 15-30s | ~100MB |
| 50 pages | 2-4 min | 1-2 min | ~200MB |
| 100 pages | 5-8 min | 2-4 min | ~250MB |
| 200 pages | 10-15 min | 5-8 min | ~300MB |

## Monitoring Commands

### Check Memory Usage (Render Dashboard)
1. Go to Render dashboard
2. Select your service
3. Click "Metrics" tab
4. Watch "Memory" graph during indexing

### Check Logs (Render)
```bash
# Look for these patterns:
✅ "ultra memory-optimized"
✅ "embedding_batch=3"
✅ "page_batch=2"
✅ "pinecone_batch=25"
❌ "MemoryError"
❌ "killed"
```

### Local Memory Monitoring (Windows)
```powershell
# Watch Python memory usage
while ($true) {
    Get-Process python -ErrorAction SilentlyContinue | 
    Select-Object Name, @{Name="Memory(MB)";Expression={[math]::Round($_.WS / 1MB, 2)}}
    Start-Sleep -Seconds 2
}
```

## Environment Variable Template

```bash
# Copy to backend/.env
EMBEDDING_BATCH_SIZE=3
PDF_PAGE_BATCH_SIZE=2
PINECONE_BATCH_SIZE=25
```

## Code Locations

| Setting | File | Line |
|---------|------|------|
| chunk_size | `backend/app/services/rag_indexer.py` | ~67 |
| EMBEDDING_BATCH_SIZE | `backend/app/services/rag_indexer.py` | ~73 |
| PDF_PAGE_BATCH_SIZE | `backend/app/services/rag_indexer.py` | ~74 |
| PINECONE_BATCH_SIZE | `backend/app/services/rag_indexer.py` | ~75 |
| Pinecone batch logic | `backend/app/services/pinecone_service.py` | ~103 |

## Emergency Rollback

If issues occur, revert to previous settings:

```bash
EMBEDDING_BATCH_SIZE=10
PDF_PAGE_BATCH_SIZE=5
# Remove PINECONE_BATCH_SIZE (uses default 100)
```

And in code:
```python
chunk_size=500
chunk_overlap=50
```

## Success Indicators

✅ Memory stays under 400MB during indexing
✅ No crashes or "killed" messages
✅ Jobs complete successfully
✅ Logs show "ultra memory-optimized"
✅ Render service stays healthy

## Failure Indicators

❌ Memory exceeds 450MB
❌ Service crashes during indexing
❌ "MemoryError" in logs
❌ Jobs stuck in "processing" state
❌ Render shows "Out of Memory"

## Support

If memory issues persist after optimization:
1. Check Render metrics for actual memory usage
2. Review logs for error patterns
3. Consider upgrading to paid tier
4. Contact Render support for memory analysis
