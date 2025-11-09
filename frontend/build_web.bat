@echo off
REM Build web app with environment variables from dart_defines.json

flutter build web --dart-define-from-file=dart_defines.json %*
