import 'package:drift/drift.dart';

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
