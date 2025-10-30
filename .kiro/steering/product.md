---
inclusion: always
---

# Product: ScholarMate

Offline-first AI research workspace for PDFs and Markdown, backed by user's Google Drive.

## Core Constraints (Non-Negotiable)

1. **User-owned storage**: All files in user's Google Drive (app folder scope only)
2. **Offline-first**: Full functionality without internet, sync when online
3. **Free-tier only**: No paid services or premium features
4. **Privacy**: End-to-end encryption for tokens and API keys
5. **Cross-platform**: Android, iOS, Web, Windows, macOS, Linux

## Feature Set

**Documents**: PDF viewer with annotations (highlight, underline, strikethrough, squiggly, comments), hybrid OCR (DeepSeek online/Tesseract offline Android), PDF→Markdown conversion, Markdown editor with preview, TTS

**AI**: RAG semantic search with citations, multi-provider support (OpenRouter, OpenAI, Claude, Gemini, Grok), user API keys (encrypted), ChromaDB vector DB

**Collaboration**: Role-based sharing (Viewer/Editor), public links, realtime presence (Supabase Realtime)

**Offline**: Drift sqlite3 cache, operation queue, auto-sync, last-write-wins conflict resolution

## UX Principles (Critical for Implementation)

1. **Assume offline**: Every feature MUST work offline or degrade gracefully
2. **Minimize backend**: Frontend handles Drive operations directly
3. **Sync visibility**: Always show sync status (synced/pending/error)
4. **Optimistic updates**: Update UI immediately, rollback on failure
5. **Actionable errors**: Provide clear recovery actions, never silent failures

## Target Users

Researchers, students, knowledge workers managing PDF libraries with AI assistance while maintaining data ownership and offline access.
