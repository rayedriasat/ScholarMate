# ScholarMate Frontend

Flutter cross-platform client for ScholarMate, supporting Android, iOS, Web, Windows, macOS, and Linux.

## Setup

1. Copy environment template:
```bash
cp ../frontend.env.template .env
```

2. Edit `.env` with your credentials

3. Install dependencies:
```bash
flutter pub get
```

## Running the App

### Web
```bash
flutter run -d chrome
```

### Desktop
```bash
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
```

### Mobile
```bash
flutter run  # Runs on connected device/emulator
```

## Project Structure

```
frontend/
├── lib/
│   ├── database/     # Drift database (offline cache)
│   ├── models/       # Data models
│   ├── services/     # Business logic services
│   ├── screens/      # UI screens
│   ├── widgets/      # Reusable UI components
│   └── main.dart     # Application entry point
├── test/             # Unit and widget tests
├── web/              # Web-specific files (including SQLite WASM)
├── pubspec.yaml      # Dependencies
└── .env              # Environment variables (not in git)
```

## Adding Dependencies

Use Flutter's package manager:
```bash
flutter pub add <package-name>
```

Example:
```bash
flutter pub add sqflite google_sign_in
```

## Database (Drift)

ScholarMate uses [Drift](https://drift.simonbinder.eu/) for cross-platform offline storage, including web support.

### Generate Database Code

After modifying table definitions in `lib/database/tables.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Database Features

- **Cross-platform**: Works on all platforms including web (using SQLite WASM)
- **Type-safe**: Compile-time checked queries
- **Offline-first**: Full functionality without internet
- **Reactive**: Stream-based updates

See [DRIFT_MIGRATION.md](DRIFT_MIGRATION.md) for detailed documentation.

## Testing

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/database_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

## Building

### Android APK
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

### Desktop
```bash
flutter build windows  # Windows
flutter build macos    # macOS
flutter build linux    # Linux
```
