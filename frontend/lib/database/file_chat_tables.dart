import 'package:drift/drift.dart';

/// File chat threads table - one thread per file
class FileChatThreads extends Table {
  TextColumn get id => text()();
  TextColumn get fileId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// File chat messages table - messages within a file chat thread
class FileChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text()();
  TextColumn get fileId => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text()();
  TextColumn get userPhotoUrl => text().nullable()();
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
