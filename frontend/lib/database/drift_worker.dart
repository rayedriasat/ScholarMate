// Web worker for Drift database operations
// This file is compiled to JavaScript and runs in a web worker
// It's automatically loaded by Drift on web platform

import 'package:drift/drift.dart';

void main() {
  // Initialize the drift worker for web
  // This allows database operations to run in a separate thread
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // The worker is set up automatically by drift_flutter
  // This file just needs to exist for the web build
}
