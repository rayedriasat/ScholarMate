@echo off
REM Quick run Flutter app with environment variables from dart_defines.json
REM Usage: run_dev.bat [device]
REM Examples:
REM   run_dev.bat          - Run on default device
REM   run_dev.bat android  - Run on Android
REM   run_dev.bat chrome   - Run on Chrome
REM   run_dev.bat edge     - Run on Edge
REM   run_dev.bat windows  - Run on Windows

if not exist "dart_defines.json" (
    echo ERROR: dart_defines.json not found!
    echo Please create it from template: copy dart_defines.json.template dart_defines.json
    exit /b 1
)

if "%1"=="" (
    flutter run --dart-define-from-file=dart_defines.json
) else (
    flutter run -d %1 --dart-define-from-file=dart_defines.json
)
