---
inclusion: always
---

# Product Overview

ScholarMate is an offline-first, Google-Drive-backed AI research workspace for managing PDFs and Markdown files.

## Core Principles

1. **User-owned storage**: All documents in user's Google Drive (app folder scope only)
2. **Offline-first**: Full functionality without internet, sync when online
3. **Free-tier only**: No paid services or premium features
4. **Privacy-focused**: End-to-end encryption for tokens and API keys
5. **Cross-platform**: Flutter app runs on Android, iOS, Web, Windows, macOS, Linux

## Key Features

### Document Management
- PDF viewing with annotations (highlight, underline, strikethrough, squiggly, comments)
- Hybrid OCR: DeepSeek (online, high accuracy) / Tesseract (offline, Android only)
- PDF to Markdown conversion with structure preservation
- Markdown editor with live preview
- Text-to-speech for PDFs

### AI & Search
- RAG-based semantic search with citations
- Multi-provider AI support (OpenRouter, OpenAI, Claude, Gemini, Grok)
- User-provided API keys (stored encrypted)
- ChromaDB vector database (self-hosted)

### Collaboration
- Role-based sharing (Viewer/Editor)
- Public link sharing
- Realtime presence tracking
- Supabase Realtime for sync (no Edge Functions)

### Offline Support
- Drift sqlite3 local cache
- Offline operation queue
- Auto-sync when connection restored
- Last-write-wins conflict resolution

## User Experience Guidelines

- **Assume offline**: Every feature must work offline or gracefully degrade
- **Minimize backend calls**: Frontend handles Drive operations directly
- **Clear sync status**: Always show user if data is synced or pending
- **Fast feedback**: Use optimistic updates with rollback on failure
- **Error recovery**: Provide clear actions when operations fail

## Target Users

Researchers, students, and knowledge workers who need to manage PDF libraries, collaborate on documents, and search using AI while maintaining data ownership and offline access.
