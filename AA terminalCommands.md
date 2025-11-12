In frontend/ folder

flutter run --dart-define-from-file=dart_defines.json
flutter run -d chrome --web-port=8080 --dart-define-from-file=dart_defines.json
flutter run -d edge --web-port=8080 --dart-define-from-file=dart_defines.json

flutter build web --dart-define-from-file=dart_defines_defang.json
flutter build apk --release --dart-define-from-file=dart_defines_defang.json

flutter pub get
flutter analyze
flutter build web

dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

In backend/ folder
uv sync
uv run run.py

For SHA1 key:

Set JAVA_HOME environment variable to use the Android Studio jdk, not the latest 25, that one is still giving issues with gradle, 23 jdk also works fine.
Edit system variable
JAVA_HOME = C:\Program Files\Android\Android Studio\jbr

in frontend/android folder
./gradlew signingReport

 