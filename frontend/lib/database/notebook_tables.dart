import 'package:drift/drift.dart';

/// Notebook folders table - stores workspace folders
class NotebookFolders extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get fileCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notebook files table - stores files within folders
class NotebookFiles extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get fileType => text()(); // pdf, markdown, image, etc.
  TextColumn get driveFileId =>
      text().nullable()(); // Link to Google Drive file
  TextColumn get content => text().nullable()(); // For markdown notes
  IntColumn get size => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notebook chat conversations table - stores AI chat per folder
class NotebookChats extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notebook chat messages table - stores chat messages
class NotebookChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get chatId => text()();
  TextColumn get userId => text()();
  TextColumn get content => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get citations => text().nullable()(); // JSON array
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notebook AI outputs table - stores generated content from AI Studio tools
class NotebookAiOutputs extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text()();
  TextColumn get userId => text()();
  TextColumn get toolType =>
      text()(); // quiz, summary, mindmap, flashcard, audio
  TextColumn get title => text()();
  TextColumn get content => text()(); // JSON content
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
