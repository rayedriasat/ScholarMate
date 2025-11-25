import 'package:drift/drift.dart';

export 'notebook_tables.dart';
export 'file_chat_tables.dart';

/// Files table - stores file/folder metadata
class Files extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get size => integer().nullable()();
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get modifiedTime => dateTime().nullable()();
  DateTimeColumn get createdTime => dateTime().nullable()();
  TextColumn get thumbnailLink => text().nullable()();
  BoolColumn get isFolder => boolean()();
  BoolColumn get isShared => boolean()();
  BoolColumn get isCached => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSynced => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached PDFs table - stores actual PDF file bytes
class CachedPdfs extends Table {
  TextColumn get fileId => text()();
  BlobColumn get pdfBytes => blob()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get fileSize => integer()();

  @override
  Set<Column> get primaryKey => {fileId};
}

/// Annotations table - stores PDF annotations
class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get fileId => text()();
  IntColumn get pageNumber => integer()();
  TextColumn get annotationType => text()();
  TextColumn get content => text().nullable()();
  TextColumn get position => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get authorId => text().nullable()();
  TextColumn get authorName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table - stores offline operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();
  TextColumn get resourceType => text()();
  TextColumn get resourceId => text().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

/// Tags table - stores user-defined tags
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// File tags table - junction table linking files to tags
class FileTags extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fileId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Chat source preferences table - stores selected sources for AI chat
class ChatSourcePreferences extends Table {
  TextColumn get userId => text()();
  TextColumn get fileId => text()();
  DateTimeColumn get selectedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, fileId};
}

/// Chat conversations table - stores chat conversation metadata
class ChatConversations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get selectedSourceIds => text()(); // JSON array of file IDs

  @override
  Set<Column> get primaryKey => {id};
}

/// Chat messages table - stores individual chat messages
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get content => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get citations => text().nullable()(); // JSON array of citations

  @override
  Set<Column> get primaryKey => {id};
}

/// Reading sessions table - tracks time spent reading files
class ReadingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fileId => text()();
  TextColumn get fileName => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Page read tracking - tracks which pages have been read
class PageReadHistory extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fileId => text()();
  IntColumn get pageNumber => integer()();
  DateTimeColumn get firstReadAt => dateTime()();
  DateTimeColumn get lastReadAt => dateTime()();
  IntColumn get readCount => integer().withDefault(const Constant(1))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached embeddings table - stores locally generated embeddings for offline AI
class CachedEmbeddings extends Table {
  TextColumn get id => text()();
  TextColumn get fileId => text()();
  IntColumn get chunkIndex => integer()();
  IntColumn get pageNumber => integer()();
  TextColumn get content => text()();
  TextColumn get embedding =>
      text()(); // JSON array of floats (384-dimensional vector)
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local chat messages table - stores offline chat history
class LocalChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get role => text()(); // 'user' or 'assistant'
  TextColumn get content => text()();
  TextColumn get citations => text().nullable()(); // JSON array of citations
  BoolColumn get generatedLocally =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Model metadata table - stores information about installed AI models
class ModelMetadata extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'embedding' or 'llm'
  IntColumn get sizeBytes => integer()();
  IntColumn get parameterCount => integer()();
  TextColumn get quantization => text()(); // Q4, Q8, etc.
  TextColumn get localPath => text()();
  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table for offline AI operations
class OfflineAiSyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get operationType =>
      text()(); // 'embedding_sync', 'chat_sync', etc.
  TextColumn get data => text()(); // JSON payload
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
