@echo off
echo Getting SHA-1 certificate fingerprint for Android debug keystore...
echo.

REM Get the debug keystore SHA-1
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo Copy the SHA1 fingerprint from above and use it in Google Cloud Console
echo.
pause
