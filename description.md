I’ve incorporated **offline-first**, **Google Drive storage**, **Google OAuth**, **RAG + AI**, **OCR/Scanner**, **PDF read aloud**, **annotations embedded**, **Viewer/Editor roles**, **public links**, **free-tier-only rules**, **realtime collaboration** with **presence + typing indicators + last-write-wins + history**, and **supabase metadata**.

Here is the **final authoritative `description.md`**:

---

# description.md — ScholarMate

## Project Title

**ScholarMate** — an offline-first, Google-Drive-backed AI research workspace (PDF + Markdown) with annotation, scanning/OCR, read-aloud, semantic search (RAG), sharing, and realtime collaboration.

---

## 1. Vision & High-level Goals

* Let users **own their files**: every file is stored in the user’s **Google Drive** (inside a single application folder).
* Provide a **fast offline-first experience**: browse folder trees, read PDFs, and add annotations while offline; auto-sync when online.
* Provide **AI-powered retrieval (RAG)** over the user’s document library, with accurate, citation-backed answers.
* Enable **realtime collaboration** for annotations and folder/file operations.
* Keep architecture **cost-free**: use only free features / free-tier services (no paid Supabase Edge, no paid Redis, no paid SaaS).
* Keep the codebase **single monorepo** (Flutter frontend + FastAPI backend + shared components).

---

## 2. Non-negotiable constraints / rules

* **ONLY** use free-tier services / free features.

* **Do NOT** use Supabase Edge Functions (paid).

* **Do NOT** use external paid services that incur ongoing bills (e.g., managed Redis on paid plans).

* **Do NOT** use Supabase Storage: Google Drive is the only file storage.

* **Flutter packages** must be added using:

  ```bash
  flutter pub add <package>
  ```

* **Python backend packages** must be managed with `uv` and `pyproject.toml` (no `requirements.txt`):

  ```bash
  uv init
  uv add <package>
  ```

* Use **Google OAuth2.0** for authentication (Drive access scope). Supabase Auth will **not** be used.

* Monorepo: The project should be a monorepo, with Flutter codes on frontend/ and Python codes on backend/ folder
---

## 3. Tech stack

* **Frontend (Flutter)**

  * Local DB / cache: **sqflite**
  * PDF Viewer / Annotation: **syncfusion_flutter_pdfviewer**
  * TTS: **flutter_tts**
  * Camera / scanner: Flutter camera + image processing plugins

* **Backend (FastAPI)**

  * Package manager: `uv` + `pyproject.toml`
  * OCR: **Tesseract** or **EasyOCR**
  * AI orchestration: **LangChain**
  * Vector DB: **ChromaDB** (self-hosted)
  * Model abstraction: pluggable provider layer (OpenRouter default, OpenAI, Claude, Gemini, Grok, etc.)

* **Metadata DB**: Supabase Postgres (free-tier) — store metadata, sharing info, encrypted tokens/keys.

* **File storage**: Google Drive (user-owned, single app folder)

* No Supabase Storage, no paid services.

---

## 4. Authentication & Identity

* Google OAuth 2.0 only (Drive scope).
* User identifier: Google OAuth `sub`.
* Drive OAuth: access limited to app folder (`drive.file`).
* Tokens (access + refresh) stored encrypted in Supabase.
* Supabase is only used for metadata & identity mapping.

---

## 5. Storage & Folder rules

* Dedicated app folder per user (`/ScholarMate/`).
* All PDFs, Markdown, attachments stored under that folder.
* **Sharing & permissions**:

  * **Roles**:

    * **Viewer** — read-only (offline read available)
    * **Editor** — full edit rights: view, annotate, add/delete/rename files/folders, reshare

  * Folder-level permissions apply recursively.

  * Public links (view-only) are created via Drive sharing.

---

## 6. Offline experience

* Full folder navigation from local cache (sqflite), same as online, with offline indicator.
* Cached PDFs viewable offline.
* Annotations offline: highlights, underline, comments (no freehand drawing). Embedded in PDF, metadata stored locally.
* Offline actions queued for auto-sync when online.
* Conflict resolution: **Last-write-wins**, history retained.

---

## 7. PDF Features & Annotations

* `syncfusion_flutter_pdfviewer` for viewing and supported annotations.
* Annotation metadata:

  * `annotation_id`, `file_id`, `author_id`, `author_name`, `timestamp_created`, `timestamp_updated`, `annotation_type`, `page_index`, `bounding_box`, `content`, `pdf_embedded_flag`, `version`
* Annotation list panel with author info, timestamps, jump-to feature.
* All annotations embedded directly in PDF bytes.

---

## 8. Scanner & OCR

* Camera capture → perspective crop → PDF.
* OCR performed in backend (Tesseract/EasyOCR).
* OCR text used for:

  * Embedding chunks → ChromaDB (RAG)
  * Searchable PDF content

---

## 9. RAG: Background indexing

* **Backend responsibilities**:

  1. Fetch files from Drive (using encrypted refresh tokens).
  2. Extract text (PDF + OCR).
  3. Chunk text → generate embeddings → store in ChromaDB.
  4. Store per-chunk metadata (`file_id`, `page_number`, offset, citation mapping).

* Trigger indexing:

  * On new/updated file (client triggers backend)
  * Manual re-index request
  * Optional: polling for file changes

* Job tracking: `pending`, `processing`, `completed`, `failed`. Status stored in Supabase.

---

## 10. AI Model Abstraction & User Keys

* **Model Provider Layer**:

  ```py
  class AIModelProvider(ABC):
      async def chat(self, prompt, config, api_key=None): ...
      async def embed(self, texts, config, api_key=None): ...
  ```

* Providers: OpenRouter (default), OpenAI, Claude, Gemini, Grok, others.

* User can provide API keys (encrypted in Supabase). Backend uses them if present.

---

## 11. Minimal Backend Responsibilities

* Only background processing: indexing, OCR, AI queries.
* Metadata management in Supabase (ingestion status, embedding info, audit logs).
* Frontend does direct Drive operations.

---

## 12. Metadata & Supabase Schema

* `users`, `files`, `folders`, `annotations`, `shares`, `ingestions`, `api_keys`, `audit_logs`.
* RLS policies to ensure user-only access.
* Sensitive fields encrypted (tokens, API keys).

---

## 13. APIs (high-level)

* `POST /api/ingest` — request indexing
* `GET /api/ingest/status` — get status
* `POST /api/ai/chat` — RAG query
* `GET /api/annotations?file_id=` — list annotations
* `POST /api/annotations/sync` — batch push
* `POST /api/ocr` — upload image/PDF for OCR
* `POST /api/api_keys` — store encrypted user key

---

## 14. Realtime Collaboration

* **Supabase Realtime + WebSockets (free tier)**

* Events:

  * Annotation creation/modification/deletion
  * File/folder rename, add, delete, move
  * Permission changes
  * Presence (who is viewing + page tracking)
  * Typing indicators for comment annotations

* **Conflict resolution**: Last-write-wins, history preserved

* Explorer and annotations update instantly across collaborators

* Realtime presence shows avatars + pages

* Editors can annotate freely and reshare

---

## 15. UI/UX Requirements

* Modern, colorful, vibrant, user-friendly

* Online/offline indicator

* File explorer:

  * Tree view (web), collapsible (mobile)
  * Thumbnails + metadata
  * Cached file indicators

* PDF viewer:

  * Toolbar: highlight, underline, comment, save
  * Annotation list panel with author avatars
  * Read-aloud controls
  * Scan → preview → save

* Sharing dialog: add users by email (Google account), role selection, public links

* AI Chat: citations clickable to open PDF page, option to save as markdown note to Drive

---

## 16. Performance & Reliability

* Handle large libraries (tens of GB):

  * Cache only opened files
  * Index asynchronously
  * Embedding throttling / user API keys

* Track ingestion job states

* Offline-first queue + auto-sync

---

## 17. Security & Privacy

* HTTPS only
* Encrypt sensitive data at rest (Supabase)
* Least-privilege OAuth scope (Drive folder only)
* Supabase RLS
* Audit logs for sharing, deletion, indexing

---

## 18. Deployment Guidance (Free-Features Only)

* Supabase: free-tier Postgres + Realtime
* FastAPI: free/low-cost host (Render/Railway/Fly/VPS)
* ChromaDB hosted with backend
* Environment variables for secrets

---

## 19. Developer Rules & Conventions

* **Flutter**: `flutter pub add <package>`
* **Backend**: `uv init` + `uv add <package>` → updates pyproject.toml
* Monorepo structure
* Encrypt all sensitive keys
* Document API endpoints in OpenAPI & README

---

## 20. Developer Workflows & Edge Cases

* If user declines storing refresh token → client uploads text to backend for indexing
* Indexing failure → show UI error + retry
* Very large PDF libraries → incremental indexing
* Embedding provider → throttle or require user key

---

## 21. Acceptance Criteria

* Google OAuth + Drive app folder connection works
* Offline-first navigation + cached PDFs + annotations
* Backend indexes PDFs for RAG
* Chat responses with clickable citations
* Sharing (Viewer/Editor) + reshare allowed
* Public links view-only
* Realtime annotations, presence, typing indicators, file/folder sync
* No paid Supabase or external services required for core flows
* PDF scanner + OCR + read-aloud functional
* AI provider abstraction + user API key supported

---

### End of file — `description.md` ✅