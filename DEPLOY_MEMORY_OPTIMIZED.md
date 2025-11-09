# Deploy Memory-Optimized Backend to Render

## Pre-Deployment Checklist

- [x] Code changes committed
- [x] Memory optimization implemented
- [x] Batch sizes reduced
- [x] GC cleanup added
- [ ] Environment variables updated
- [ ] Deployed to Render
- [ ] Tested with sample PDF

## Step 1: Update Render Environment Variables

Go to Render Dashboard → Your Service → Environment

### Add/Update These Variables:

```bash
# Memory Optimization (CRITICAL)
EMBEDDING_BATCH_SIZE=3
PDF_PAGE_BATCH_SIZE=2
PINECONE_BATCH_SIZE=25
```

### Verify These Exist:

```bash
# Required for operation
PINECONE_API_KEY=your_key
GROQ_API_KEY=your_key
SUPABASE_URL=your_url
SUPABASE_KEY=your_key
SUPABASE_SERVICE_KEY=your_key
GOOGLE_CLIENT_ID=your_id
GOOGLE_CLIENT_SECRET=your_secret
ENCRYPTION_KEY=your_key

# Optional but recommended
LOG_LEVEL=INFO
DEBUG=False
```

## Step 2: Deploy to Render

### Option A: Auto-Deploy (Recommended)

If you have auto-deploy enabled:

1. Commit and push changes:
   ```bash
   git add .
   git commit -m "Memory optimization: reduce batch sizes for 512MB limit"
   git push origin main
   ```

2. Render will automatically deploy
3. Monitor deployment in Render dashboard

### Option B: Manual Deploy

1. Go to Render Dashboard
2. Select your service
3. Click "Manual Deploy" → "Deploy latest commit"
4. Wait for deployment to complete

## Step 3: Monitor Deployment

### Watch Build Logs

Look for these success indicators:

```
✅ Building...
✅ Installing dependencies...
✅ Starting server...
✅ Server started on port 8000
```

### Check Application Logs

After deployment, check logs for:

```
✅ "Pinecone initialized"
✅ "GROQ chat model initialized"
✅ "Text splitter initialized: chunk_size=400, embedding_batch=3, page_batch=2, pinecone_batch=25"
✅ "ultra memory-optimized"
```

## Step 4: Test with Sample PDF

### 4.1 Test Small PDF (5-10 pages)

1. Upload a small PDF through your app
2. Start indexing
3. Monitor Render logs:
   ```
   ✅ "Creating indexing job"
   ✅ "Processing indexing job"
   ✅ "Extracted X pages"
   ✅ "Created X chunks (ultra memory-optimized)"
   ✅ "Generating embeddings for X documents in batches of 3"
   ✅ "Stored batch X/Y"
   ✅ "Indexing job completed successfully"
   ```

4. Check Render Metrics → Memory:
   - Should stay under 200MB
   - No spikes above 300MB

### 4.2 Test Medium PDF (20-30 pages)

1. Upload a medium PDF
2. Start indexing
3. Monitor memory usage in Render dashboard
4. Expected:
   - Peak: 200-300MB
   - Duration: 2-4 minutes
   - Status: Completed

### 4.3 Test Large PDF (50-100 pages)

1. Upload a large PDF
2. Start indexing
3. Monitor closely:
   - Memory should cycle between 150-250MB
   - Should NOT exceed 400MB
   - Duration: 5-10 minutes
   - Status: Completed

## Step 5: Verify Memory Metrics

### In Render Dashboard

1. Go to your service
2. Click "Metrics" tab
3. Check "Memory" graph

**Success Criteria:**
- ✅ Memory stays under 400MB
- ✅ No sudden spikes to 500MB+
- ✅ Memory returns to baseline after indexing
- ✅ No "Out of Memory" errors

**Failure Indicators:**
- ❌ Memory exceeds 450MB
- ❌ Service crashes during indexing
- ❌ "killed" or "MemoryError" in logs
- ❌ Service restarts automatically

## Step 6: Troubleshooting

### If Memory Still Too High (>400MB)

**Option 1: Further reduce batch sizes**

Update Render environment variables:
```bash
EMBEDDING_BATCH_SIZE=2
PDF_PAGE_BATCH_SIZE=1
PINECONE_BATCH_SIZE=10
```

Redeploy and test again.

**Option 2: Increase GC delays**

Edit `backend/app/services/rag_indexer.py`:
```python
# Change all asyncio.sleep values:
await asyncio.sleep(0.5)  # Increase from 0.2-0.3
```

Commit, push, and redeploy.

**Option 3: Reduce chunk size**

Edit `backend/app/services/rag_indexer.py`:
```python
self.text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=300,  # Down from 400
    chunk_overlap=30,  # Down from 40
    ...
)
```

Commit, push, and redeploy.

### If Service Crashes

1. Check Render logs for error message
2. Look for "MemoryError" or "killed"
3. Check memory graph for spike timing
4. Apply Option 1 above (reduce batch sizes)

### If Processing Too Slow

**Current settings are optimized for stability over speed.**

If speed is critical:
1. Consider upgrading to Render Starter plan ($7/month, 1GB RAM)
2. Then increase batch sizes:
   ```bash
   EMBEDDING_BATCH_SIZE=10
   PDF_PAGE_BATCH_SIZE=5
   PINECONE_BATCH_SIZE=50
   ```

## Step 7: Production Monitoring

### Set Up Alerts (Optional)

In Render Dashboard:
1. Go to Settings → Notifications
2. Add email for service alerts
3. Enable "Service Down" notifications

### Regular Checks

**Daily:**
- Check service health status
- Review error logs

**Weekly:**
- Review memory usage trends
- Check average indexing times
- Monitor job success rate

**Monthly:**
- Review Render usage/costs
- Consider plan upgrade if needed
- Optimize based on usage patterns

## Expected Performance

### Processing Times (After Optimization)

| PDF Size | Chunks | Time | Memory Peak |
|----------|--------|------|-------------|
| 10 pages | ~100 | 30-60s | ~100MB |
| 30 pages | ~300 | 2-3 min | ~200MB |
| 50 pages | ~500 | 3-5 min | ~250MB |
| 100 pages | ~1000 | 6-10 min | ~300MB |

### Memory Usage Pattern

```
Baseline: 50-80MB (idle)
Processing: 150-250MB (cycling)
Peak: 250-300MB (max)
After completion: 60-80MB (cleanup)
```

## Rollback Plan

If optimization causes issues:

1. **Revert environment variables:**
   ```bash
   EMBEDDING_BATCH_SIZE=10
   PDF_PAGE_BATCH_SIZE=5
   # Remove PINECONE_BATCH_SIZE
   ```

2. **Revert code changes:**
   ```bash
   git revert HEAD
   git push origin main
   ```

3. **Consider upgrading Render plan** instead

## Success Criteria

✅ Service deploys successfully
✅ No crashes during indexing
✅ Memory stays under 400MB
✅ Jobs complete successfully
✅ Logs show "ultra memory-optimized"
✅ No "MemoryError" or "killed" messages
✅ Service remains healthy after multiple indexing jobs

## Next Steps After Successful Deployment

1. **Document actual memory usage** from Render metrics
2. **Fine-tune batch sizes** if needed based on real data
3. **Monitor for 1 week** to ensure stability
4. **Consider plan upgrade** if processing speed becomes critical
5. **Update team** on new processing times

## Support Resources

- **Render Docs:** https://render.com/docs
- **Render Support:** support@render.com
- **Memory Optimization Guide:** See `MEMORY_OPTIMIZATION_COMPLETE.md`
- **Quick Reference:** See `MEMORY_SETTINGS_QUICK_REF.md`
- **Flow Diagram:** See `MEMORY_FLOW_DIAGRAM.md`

## Emergency Contacts

If critical issues occur:
1. Check Render status page: https://status.render.com
2. Review Render logs immediately
3. Rollback if necessary (see Rollback Plan above)
4. Contact Render support if platform issue

---

**Remember:** These optimizations prioritize stability over speed. The backend will process PDFs slower but reliably within the 512MB memory limit.
