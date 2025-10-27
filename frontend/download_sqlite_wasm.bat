@echo off
echo Downloading SQLite WASM files for web support...

REM Create web directory if it doesn't exist
if not exist "web" mkdir web

REM Download sqlite3.wasm
echo Downloading sqlite3.wasm...
curl -L -o web/sqlite3.wasm https://github.com/simolus3/sqlite3.dart/releases/download/v2.4.6/sqlite3.wasm

REM Download sqlite3.wasm.js
echo Downloading sqlite3.wasm.js...
curl -L -o web/sqlite3.wasm.js https://github.com/simolus3/sqlite3.dart/releases/download/v2.4.6/sqlite3.wasm.js

echo.
echo SQLite WASM files downloaded successfully!
echo You can now run the app on web with: flutter run -d chrome
pause
