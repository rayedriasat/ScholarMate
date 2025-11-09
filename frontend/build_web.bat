@echo off
REM Build web app with environment variables from dart_defines_prod.json

flutter build web --dart-define-from-file=dart_defines_prod.json %*
