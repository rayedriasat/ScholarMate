@echo off
echo Downloading SQLite WASM and Drift worker files for web support...

REM Create web directory if it doesn't exist
if not exist "web" mkdir web

REM Download sqlite3.wasm from sqlite3.dart releases
echo Downloading sqlite3.wasm (731 KB)...
curl -L -o web/sqlite3.wasm https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.3/sqlite3.wasm

REM Download drift_worker.js from drift releases (NOT drift_worker.dart.js yet)
echo Downloading drift_worker.dart.js (355 KB)...
curl -L -o web/drift_worker.dart.js https://github.com/simolus3/drift/releases/download/drift-2.29.0/drift_worker.js

echo.
echo Files downloaded successfully!
echo.
echo Your web/ directory should now contain:
echo   - sqlite3.wasm (731 KB)
echo   - drift_worker.dart.js (355 KB)
echo.
echo You can now run the app on web with: flutter run -d chrome
pause
