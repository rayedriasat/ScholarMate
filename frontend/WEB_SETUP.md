# Web Setup Guide for ScholarMate

## Required Files for Web Support

Drift requires two files in the `web/` directory:

1. **`sqlite3.wasm`** (~731 KB) - SQLite compiled to WebAssembly
2. **`drift_worker.dart.js`** (~355 KB) - Precompiled Drift web worker

## Quick Setup

Run the download script:

```bash
cd frontend
download_sqlite_wasm.bat
```

This downloads the official prebuilt files from:
- sqlite3.wasm: https://github.com/simolus3/sqlite3.dart/releases
- drift_worker.dart.js: https://github.com/simolus3/drift/releases

## Verify Installation

Check that files were downloaded correctly:

```bash
dir web\sqlite3.wasm
dir web\drift_worker.dart.js
```

Expected sizes:
- sqlite3.wasm: ~731,818 bytes
- drift_worker.dart.js: ~355,579 bytes

## Run on Web

```bash
flutter run -d chrome
```

## Optional: Enable Better Performance

For better performance, serve your app with these headers:

```bash
flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
```

**Note:** These headers may break Google Sign-In popups. Test carefully before using in production.

## Troubleshooting

### Error: "expected magic word 00 61 73 6d"

This means `sqlite3.wasm` is missing or corrupted. Re-run:

```bash
download_sqlite_wasm.bat
```

### Error: "Failed to load drift_worker.dart.js"

Make sure the file exists in `web/` directory and is the correct size (~355 KB).

### Database not persisting

Check browser console for storage implementation:
- `opfsShared` or `opfsLocks` = Best (full persistence)
- `sharedIndexedDb` = Good (full persistence)
- `unsafeIndexedDb` = Limited (don't use multiple tabs)
- `inMemory` = No persistence

## How It Works

1. Flutter loads `sqlite3.wasm` in the browser
2. Drift spawns `drift_worker.dart.js` as a Web Worker
3. Database operations run in the worker (non-blocking)
4. Data persists using browser storage APIs (OPFS or IndexedDB)

## References

- [Drift Web Documentation](https://drift.simonbinder.eu/platforms/web/)
- [sqlite3.dart Releases](https://github.com/simolus3/sqlite3.dart/releases)
- [Drift Releases](https://github.com/simolus3/drift/releases)
