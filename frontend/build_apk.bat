@echo off
REM Build Android APK with environment variables from dart_defines.json

flutter build apk --dart-define-from-file=dart_defines.json %*
