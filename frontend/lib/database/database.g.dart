// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FilesTable extends Files with TableInfo<$FilesTable, File> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedTimeMeta = const VerificationMeta(
    'modifiedTime',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedTime = GeneratedColumn<DateTime>(
    'modified_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdTimeMeta = const VerificationMeta(
    'createdTime',
  );
  @override
  late final GeneratedColumn<DateTime> createdTime = GeneratedColumn<DateTime>(
    'created_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailLinkMeta = const VerificationMeta(
    'thumbnailLink',
  );
  @override
  late final GeneratedColumn<String> thumbnailLink = GeneratedColumn<String>(
    'thumbnail_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFolderMeta = const VerificationMeta(
    'isFolder',
  );
  @override
  late final GeneratedColumn<bool> isFolder = GeneratedColumn<bool>(
    'is_folder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_folder" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isCachedMeta = const VerificationMeta(
    'isCached',
  );
  @override
  late final GeneratedColumn<bool> isCached = GeneratedColumn<bool>(
    'is_cached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedMeta = const VerificationMeta(
    'lastSynced',
  );
  @override
  late final GeneratedColumn<DateTime> lastSynced = GeneratedColumn<DateTime>(
    'last_synced',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    mimeType,
    size,
    parentId,
    modifiedTime,
    createdTime,
    thumbnailLink,
    isFolder,
    isShared,
    isCached,
    lastSynced,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'files';
  @override
  VerificationContext validateIntegrity(
    Insertable<File> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('modified_time')) {
      context.handle(
        _modifiedTimeMeta,
        modifiedTime.isAcceptableOrUnknown(
          data['modified_time']!,
          _modifiedTimeMeta,
        ),
      );
    }
    if (data.containsKey('created_time')) {
      context.handle(
        _createdTimeMeta,
        createdTime.isAcceptableOrUnknown(
          data['created_time']!,
          _createdTimeMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_link')) {
      context.handle(
        _thumbnailLinkMeta,
        thumbnailLink.isAcceptableOrUnknown(
          data['thumbnail_link']!,
          _thumbnailLinkMeta,
        ),
      );
    }
    if (data.containsKey('is_folder')) {
      context.handle(
        _isFolderMeta,
        isFolder.isAcceptableOrUnknown(data['is_folder']!, _isFolderMeta),
      );
    } else if (isInserting) {
      context.missing(_isFolderMeta);
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    } else if (isInserting) {
      context.missing(_isSharedMeta);
    }
    if (data.containsKey('is_cached')) {
      context.handle(
        _isCachedMeta,
        isCached.isAcceptableOrUnknown(data['is_cached']!, _isCachedMeta),
      );
    }
    if (data.containsKey('last_synced')) {
      context.handle(
        _lastSyncedMeta,
        lastSynced.isAcceptableOrUnknown(data['last_synced']!, _lastSyncedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  File map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return File(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      modifiedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_time'],
      ),
      createdTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_time'],
      ),
      thumbnailLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_link'],
      ),
      isFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_folder'],
      )!,
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
      isCached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cached'],
      )!,
      lastSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $FilesTable createAlias(String alias) {
    return $FilesTable(attachedDatabase, alias);
  }
}

class File extends DataClass implements Insertable<File> {
  final String id;
  final String name;
  final String? mimeType;
  final int? size;
  final String? parentId;
  final DateTime? modifiedTime;
  final DateTime? createdTime;
  final String? thumbnailLink;
  final bool isFolder;
  final bool isShared;
  final bool isCached;
  final DateTime? lastSynced;
  final String syncStatus;
  const File({
    required this.id,
    required this.name,
    this.mimeType,
    this.size,
    this.parentId,
    this.modifiedTime,
    this.createdTime,
    this.thumbnailLink,
    required this.isFolder,
    required this.isShared,
    required this.isCached,
    this.lastSynced,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || modifiedTime != null) {
      map['modified_time'] = Variable<DateTime>(modifiedTime);
    }
    if (!nullToAbsent || createdTime != null) {
      map['created_time'] = Variable<DateTime>(createdTime);
    }
    if (!nullToAbsent || thumbnailLink != null) {
      map['thumbnail_link'] = Variable<String>(thumbnailLink);
    }
    map['is_folder'] = Variable<bool>(isFolder);
    map['is_shared'] = Variable<bool>(isShared);
    map['is_cached'] = Variable<bool>(isCached);
    if (!nullToAbsent || lastSynced != null) {
      map['last_synced'] = Variable<DateTime>(lastSynced);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  FilesCompanion toCompanion(bool nullToAbsent) {
    return FilesCompanion(
      id: Value(id),
      name: Value(name),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      modifiedTime: modifiedTime == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedTime),
      createdTime: createdTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createdTime),
      thumbnailLink: thumbnailLink == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailLink),
      isFolder: Value(isFolder),
      isShared: Value(isShared),
      isCached: Value(isCached),
      lastSynced: lastSynced == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSynced),
      syncStatus: Value(syncStatus),
    );
  }

  factory File.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return File(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      size: serializer.fromJson<int?>(json['size']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      modifiedTime: serializer.fromJson<DateTime?>(json['modifiedTime']),
      createdTime: serializer.fromJson<DateTime?>(json['createdTime']),
      thumbnailLink: serializer.fromJson<String?>(json['thumbnailLink']),
      isFolder: serializer.fromJson<bool>(json['isFolder']),
      isShared: serializer.fromJson<bool>(json['isShared']),
      isCached: serializer.fromJson<bool>(json['isCached']),
      lastSynced: serializer.fromJson<DateTime?>(json['lastSynced']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'mimeType': serializer.toJson<String?>(mimeType),
      'size': serializer.toJson<int?>(size),
      'parentId': serializer.toJson<String?>(parentId),
      'modifiedTime': serializer.toJson<DateTime?>(modifiedTime),
      'createdTime': serializer.toJson<DateTime?>(createdTime),
      'thumbnailLink': serializer.toJson<String?>(thumbnailLink),
      'isFolder': serializer.toJson<bool>(isFolder),
      'isShared': serializer.toJson<bool>(isShared),
      'isCached': serializer.toJson<bool>(isCached),
      'lastSynced': serializer.toJson<DateTime?>(lastSynced),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  File copyWith({
    String? id,
    String? name,
    Value<String?> mimeType = const Value.absent(),
    Value<int?> size = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    Value<DateTime?> modifiedTime = const Value.absent(),
    Value<DateTime?> createdTime = const Value.absent(),
    Value<String?> thumbnailLink = const Value.absent(),
    bool? isFolder,
    bool? isShared,
    bool? isCached,
    Value<DateTime?> lastSynced = const Value.absent(),
    String? syncStatus,
  }) => File(
    id: id ?? this.id,
    name: name ?? this.name,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    size: size.present ? size.value : this.size,
    parentId: parentId.present ? parentId.value : this.parentId,
    modifiedTime: modifiedTime.present ? modifiedTime.value : this.modifiedTime,
    createdTime: createdTime.present ? createdTime.value : this.createdTime,
    thumbnailLink: thumbnailLink.present
        ? thumbnailLink.value
        : this.thumbnailLink,
    isFolder: isFolder ?? this.isFolder,
    isShared: isShared ?? this.isShared,
    isCached: isCached ?? this.isCached,
    lastSynced: lastSynced.present ? lastSynced.value : this.lastSynced,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  File copyWithCompanion(FilesCompanion data) {
    return File(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      size: data.size.present ? data.size.value : this.size,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      modifiedTime: data.modifiedTime.present
          ? data.modifiedTime.value
          : this.modifiedTime,
      createdTime: data.createdTime.present
          ? data.createdTime.value
          : this.createdTime,
      thumbnailLink: data.thumbnailLink.present
          ? data.thumbnailLink.value
          : this.thumbnailLink,
      isFolder: data.isFolder.present ? data.isFolder.value : this.isFolder,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
      isCached: data.isCached.present ? data.isCached.value : this.isCached,
      lastSynced: data.lastSynced.present
          ? data.lastSynced.value
          : this.lastSynced,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('File(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('parentId: $parentId, ')
          ..write('modifiedTime: $modifiedTime, ')
          ..write('createdTime: $createdTime, ')
          ..write('thumbnailLink: $thumbnailLink, ')
          ..write('isFolder: $isFolder, ')
          ..write('isShared: $isShared, ')
          ..write('isCached: $isCached, ')
          ..write('lastSynced: $lastSynced, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mimeType,
    size,
    parentId,
    modifiedTime,
    createdTime,
    thumbnailLink,
    isFolder,
    isShared,
    isCached,
    lastSynced,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is File &&
          other.id == this.id &&
          other.name == this.name &&
          other.mimeType == this.mimeType &&
          other.size == this.size &&
          other.parentId == this.parentId &&
          other.modifiedTime == this.modifiedTime &&
          other.createdTime == this.createdTime &&
          other.thumbnailLink == this.thumbnailLink &&
          other.isFolder == this.isFolder &&
          other.isShared == this.isShared &&
          other.isCached == this.isCached &&
          other.lastSynced == this.lastSynced &&
          other.syncStatus == this.syncStatus);
}

class FilesCompanion extends UpdateCompanion<File> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> mimeType;
  final Value<int?> size;
  final Value<String?> parentId;
  final Value<DateTime?> modifiedTime;
  final Value<DateTime?> createdTime;
  final Value<String?> thumbnailLink;
  final Value<bool> isFolder;
  final Value<bool> isShared;
  final Value<bool> isCached;
  final Value<DateTime?> lastSynced;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const FilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.parentId = const Value.absent(),
    this.modifiedTime = const Value.absent(),
    this.createdTime = const Value.absent(),
    this.thumbnailLink = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.isShared = const Value.absent(),
    this.isCached = const Value.absent(),
    this.lastSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilesCompanion.insert({
    required String id,
    required String name,
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.parentId = const Value.absent(),
    this.modifiedTime = const Value.absent(),
    this.createdTime = const Value.absent(),
    this.thumbnailLink = const Value.absent(),
    required bool isFolder,
    required bool isShared,
    this.isCached = const Value.absent(),
    this.lastSynced = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isFolder = Value(isFolder),
       isShared = Value(isShared);
  static Insertable<File> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? mimeType,
    Expression<int>? size,
    Expression<String>? parentId,
    Expression<DateTime>? modifiedTime,
    Expression<DateTime>? createdTime,
    Expression<String>? thumbnailLink,
    Expression<bool>? isFolder,
    Expression<bool>? isShared,
    Expression<bool>? isCached,
    Expression<DateTime>? lastSynced,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mimeType != null) 'mime_type': mimeType,
      if (size != null) 'size': size,
      if (parentId != null) 'parent_id': parentId,
      if (modifiedTime != null) 'modified_time': modifiedTime,
      if (createdTime != null) 'created_time': createdTime,
      if (thumbnailLink != null) 'thumbnail_link': thumbnailLink,
      if (isFolder != null) 'is_folder': isFolder,
      if (isShared != null) 'is_shared': isShared,
      if (isCached != null) 'is_cached': isCached,
      if (lastSynced != null) 'last_synced': lastSynced,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? mimeType,
    Value<int?>? size,
    Value<String?>? parentId,
    Value<DateTime?>? modifiedTime,
    Value<DateTime?>? createdTime,
    Value<String?>? thumbnailLink,
    Value<bool>? isFolder,
    Value<bool>? isShared,
    Value<bool>? isCached,
    Value<DateTime?>? lastSynced,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return FilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      parentId: parentId ?? this.parentId,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdTime: createdTime ?? this.createdTime,
      thumbnailLink: thumbnailLink ?? this.thumbnailLink,
      isFolder: isFolder ?? this.isFolder,
      isShared: isShared ?? this.isShared,
      isCached: isCached ?? this.isCached,
      lastSynced: lastSynced ?? this.lastSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (modifiedTime.present) {
      map['modified_time'] = Variable<DateTime>(modifiedTime.value);
    }
    if (createdTime.present) {
      map['created_time'] = Variable<DateTime>(createdTime.value);
    }
    if (thumbnailLink.present) {
      map['thumbnail_link'] = Variable<String>(thumbnailLink.value);
    }
    if (isFolder.present) {
      map['is_folder'] = Variable<bool>(isFolder.value);
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (isCached.present) {
      map['is_cached'] = Variable<bool>(isCached.value);
    }
    if (lastSynced.present) {
      map['last_synced'] = Variable<DateTime>(lastSynced.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('parentId: $parentId, ')
          ..write('modifiedTime: $modifiedTime, ')
          ..write('createdTime: $createdTime, ')
          ..write('thumbnailLink: $thumbnailLink, ')
          ..write('isFolder: $isFolder, ')
          ..write('isShared: $isShared, ')
          ..write('isCached: $isCached, ')
          ..write('lastSynced: $lastSynced, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPdfsTable extends CachedPdfs
    with TableInfo<$CachedPdfsTable, CachedPdf> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPdfsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pdfBytesMeta = const VerificationMeta(
    'pdfBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> pdfBytes = GeneratedColumn<Uint8List>(
    'pdf_bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, pdfBytes, cachedAt, fileSize];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_pdfs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPdf> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('pdf_bytes')) {
      context.handle(
        _pdfBytesMeta,
        pdfBytes.isAcceptableOrUnknown(data['pdf_bytes']!, _pdfBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_pdfBytesMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  CachedPdf map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPdf(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      pdfBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pdf_bytes'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
    );
  }

  @override
  $CachedPdfsTable createAlias(String alias) {
    return $CachedPdfsTable(attachedDatabase, alias);
  }
}

class CachedPdf extends DataClass implements Insertable<CachedPdf> {
  final String fileId;
  final Uint8List pdfBytes;
  final DateTime cachedAt;
  final int fileSize;
  const CachedPdf({
    required this.fileId,
    required this.pdfBytes,
    required this.cachedAt,
    required this.fileSize,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['pdf_bytes'] = Variable<Uint8List>(pdfBytes);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['file_size'] = Variable<int>(fileSize);
    return map;
  }

  CachedPdfsCompanion toCompanion(bool nullToAbsent) {
    return CachedPdfsCompanion(
      fileId: Value(fileId),
      pdfBytes: Value(pdfBytes),
      cachedAt: Value(cachedAt),
      fileSize: Value(fileSize),
    );
  }

  factory CachedPdf.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPdf(
      fileId: serializer.fromJson<String>(json['fileId']),
      pdfBytes: serializer.fromJson<Uint8List>(json['pdfBytes']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'pdfBytes': serializer.toJson<Uint8List>(pdfBytes),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'fileSize': serializer.toJson<int>(fileSize),
    };
  }

  CachedPdf copyWith({
    String? fileId,
    Uint8List? pdfBytes,
    DateTime? cachedAt,
    int? fileSize,
  }) => CachedPdf(
    fileId: fileId ?? this.fileId,
    pdfBytes: pdfBytes ?? this.pdfBytes,
    cachedAt: cachedAt ?? this.cachedAt,
    fileSize: fileSize ?? this.fileSize,
  );
  CachedPdf copyWithCompanion(CachedPdfsCompanion data) {
    return CachedPdf(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      pdfBytes: data.pdfBytes.present ? data.pdfBytes.value : this.pdfBytes,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPdf(')
          ..write('fileId: $fileId, ')
          ..write('pdfBytes: $pdfBytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('fileSize: $fileSize')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fileId,
    $driftBlobEquality.hash(pdfBytes),
    cachedAt,
    fileSize,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPdf &&
          other.fileId == this.fileId &&
          $driftBlobEquality.equals(other.pdfBytes, this.pdfBytes) &&
          other.cachedAt == this.cachedAt &&
          other.fileSize == this.fileSize);
}

class CachedPdfsCompanion extends UpdateCompanion<CachedPdf> {
  final Value<String> fileId;
  final Value<Uint8List> pdfBytes;
  final Value<DateTime> cachedAt;
  final Value<int> fileSize;
  final Value<int> rowid;
  const CachedPdfsCompanion({
    this.fileId = const Value.absent(),
    this.pdfBytes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPdfsCompanion.insert({
    required String fileId,
    required Uint8List pdfBytes,
    required DateTime cachedAt,
    required int fileSize,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       pdfBytes = Value(pdfBytes),
       cachedAt = Value(cachedAt),
       fileSize = Value(fileSize);
  static Insertable<CachedPdf> custom({
    Expression<String>? fileId,
    Expression<Uint8List>? pdfBytes,
    Expression<DateTime>? cachedAt,
    Expression<int>? fileSize,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (pdfBytes != null) 'pdf_bytes': pdfBytes,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (fileSize != null) 'file_size': fileSize,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPdfsCompanion copyWith({
    Value<String>? fileId,
    Value<Uint8List>? pdfBytes,
    Value<DateTime>? cachedAt,
    Value<int>? fileSize,
    Value<int>? rowid,
  }) {
    return CachedPdfsCompanion(
      fileId: fileId ?? this.fileId,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      cachedAt: cachedAt ?? this.cachedAt,
      fileSize: fileSize ?? this.fileSize,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (pdfBytes.present) {
      map['pdf_bytes'] = Variable<Uint8List>(pdfBytes.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPdfsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('pdfBytes: $pdfBytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('fileSize: $fileSize, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annotationTypeMeta = const VerificationMeta(
    'annotationType',
  );
  @override
  late final GeneratedColumn<String> annotationType = GeneratedColumn<String>(
    'annotation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileId,
    pageNumber,
    annotationType,
    content,
    position,
    color,
    authorId,
    authorName,
    createdAt,
    modifiedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Annotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('annotation_type')) {
      context.handle(
        _annotationTypeMeta,
        annotationType.isAcceptableOrUnknown(
          data['annotation_type']!,
          _annotationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annotationTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      annotationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotation_type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      ),
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final String id;
  final String fileId;
  final int pageNumber;
  final String annotationType;
  final String? content;
  final String? position;
  final String? color;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isSynced;
  const Annotation({
    required this.id,
    required this.fileId,
    required this.pageNumber,
    required this.annotationType,
    this.content,
    this.position,
    this.color,
    this.authorId,
    this.authorName,
    required this.createdAt,
    required this.modifiedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_id'] = Variable<String>(fileId);
    map['page_number'] = Variable<int>(pageNumber);
    map['annotation_type'] = Variable<String>(annotationType);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || authorId != null) {
      map['author_id'] = Variable<String>(authorId);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      fileId: Value(fileId),
      pageNumber: Value(pageNumber),
      annotationType: Value(annotationType),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      authorId: authorId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorId),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      isSynced: Value(isSynced),
    );
  }

  factory Annotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<String>(json['id']),
      fileId: serializer.fromJson<String>(json['fileId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      annotationType: serializer.fromJson<String>(json['annotationType']),
      content: serializer.fromJson<String?>(json['content']),
      position: serializer.fromJson<String?>(json['position']),
      color: serializer.fromJson<String?>(json['color']),
      authorId: serializer.fromJson<String?>(json['authorId']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileId': serializer.toJson<String>(fileId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'annotationType': serializer.toJson<String>(annotationType),
      'content': serializer.toJson<String?>(content),
      'position': serializer.toJson<String?>(position),
      'color': serializer.toJson<String?>(color),
      'authorId': serializer.toJson<String?>(authorId),
      'authorName': serializer.toJson<String?>(authorName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Annotation copyWith({
    String? id,
    String? fileId,
    int? pageNumber,
    String? annotationType,
    Value<String?> content = const Value.absent(),
    Value<String?> position = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> authorId = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isSynced,
  }) => Annotation(
    id: id ?? this.id,
    fileId: fileId ?? this.fileId,
    pageNumber: pageNumber ?? this.pageNumber,
    annotationType: annotationType ?? this.annotationType,
    content: content.present ? content.value : this.content,
    position: position.present ? position.value : this.position,
    color: color.present ? color.value : this.color,
    authorId: authorId.present ? authorId.value : this.authorId,
    authorName: authorName.present ? authorName.value : this.authorName,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      annotationType: data.annotationType.present
          ? data.annotationType.value
          : this.annotationType,
      content: data.content.present ? data.content.value : this.content,
      position: data.position.present ? data.position.value : this.position,
      color: data.color.present ? data.color.value : this.color,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('annotationType: $annotationType, ')
          ..write('content: $content, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileId,
    pageNumber,
    annotationType,
    content,
    position,
    color,
    authorId,
    authorName,
    createdAt,
    modifiedAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.fileId == this.fileId &&
          other.pageNumber == this.pageNumber &&
          other.annotationType == this.annotationType &&
          other.content == this.content &&
          other.position == this.position &&
          other.color == this.color &&
          other.authorId == this.authorId &&
          other.authorName == this.authorName &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.isSynced == this.isSynced);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<String> id;
  final Value<String> fileId;
  final Value<int> pageNumber;
  final Value<String> annotationType;
  final Value<String?> content;
  final Value<String?> position;
  final Value<String?> color;
  final Value<String?> authorId;
  final Value<String?> authorName;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.fileId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.annotationType = const Value.absent(),
    this.content = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    required String id,
    required String fileId,
    required int pageNumber,
    required String annotationType,
    this.content = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fileId = Value(fileId),
       pageNumber = Value(pageNumber),
       annotationType = Value(annotationType),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Annotation> custom({
    Expression<String>? id,
    Expression<String>? fileId,
    Expression<int>? pageNumber,
    Expression<String>? annotationType,
    Expression<String>? content,
    Expression<String>? position,
    Expression<String>? color,
    Expression<String>? authorId,
    Expression<String>? authorName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileId != null) 'file_id': fileId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (annotationType != null) 'annotation_type': annotationType,
      if (content != null) 'content': content,
      if (position != null) 'position': position,
      if (color != null) 'color': color,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? fileId,
    Value<int>? pageNumber,
    Value<String>? annotationType,
    Value<String?>? content,
    Value<String?>? position,
    Value<String?>? color,
    Value<String?>? authorId,
    Value<String?>? authorName,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      pageNumber: pageNumber ?? this.pageNumber,
      annotationType: annotationType ?? this.annotationType,
      content: content ?? this.content,
      position: position ?? this.position,
      color: color ?? this.color,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (annotationType.present) {
      map['annotation_type'] = Variable<String>(annotationType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('annotationType: $annotationType, ')
          ..write('content: $content, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceTypeMeta = const VerificationMeta(
    'resourceType',
  );
  @override
  late final GeneratedColumn<String> resourceType = GeneratedColumn<String>(
    'resource_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    resourceType,
    resourceId,
    payload,
    createdAt,
    retryCount,
    lastError,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('resource_type')) {
      context.handle(
        _resourceTypeMeta,
        resourceType.isAcceptableOrUnknown(
          data['resource_type']!,
          _resourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resourceTypeMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      resourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_type'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String operationType;
  final String resourceType;
  final String? resourceId;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final String status;
  const SyncQueueData({
    required this.id,
    required this.operationType,
    required this.resourceType,
    this.resourceId,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['resource_type'] = Variable<String>(resourceType);
    if (!nullToAbsent || resourceId != null) {
      map['resource_id'] = Variable<String>(resourceId);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operationType: Value(operationType),
      resourceType: Value(resourceType),
      resourceId: resourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      resourceType: serializer.fromJson<String>(json['resourceType']),
      resourceId: serializer.fromJson<String?>(json['resourceId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationType': serializer.toJson<String>(operationType),
      'resourceType': serializer.toJson<String>(resourceType),
      'resourceId': serializer.toJson<String?>(resourceId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? operationType,
    String? resourceType,
    Value<String?> resourceId = const Value.absent(),
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    String? status,
  }) => SyncQueueData(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    resourceType: resourceType ?? this.resourceType,
    resourceId: resourceId.present ? resourceId.value : this.resourceId,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      resourceType: data.resourceType.present
          ? data.resourceType.value
          : this.resourceType,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    resourceType,
    resourceId,
    payload,
    createdAt,
    retryCount,
    lastError,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.resourceType == this.resourceType &&
          other.resourceId == this.resourceId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> operationType;
  final Value<String> resourceType;
  final Value<String?> resourceId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<String> status;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.resourceType = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String operationType,
    required String resourceType,
    this.resourceId = const Value.absent(),
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  }) : operationType = Value(operationType),
       resourceType = Value(resourceType),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? operationType,
    Expression<String>? resourceType,
    Expression<String>? resourceId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (resourceType != null) 'resource_type': resourceType,
      if (resourceId != null) 'resource_id': resourceId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? operationType,
    Value<String>? resourceType,
    Value<String?>? resourceId,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<String>? status,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (resourceType.present) {
      map['resource_type'] = Variable<String>(resourceType.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FilesTable files = $FilesTable(this);
  late final $CachedPdfsTable cachedPdfs = $CachedPdfsTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    files,
    cachedPdfs,
    annotations,
    syncQueue,
  ];
}

typedef $$FilesTableCreateCompanionBuilder =
    FilesCompanion Function({
      required String id,
      required String name,
      Value<String?> mimeType,
      Value<int?> size,
      Value<String?> parentId,
      Value<DateTime?> modifiedTime,
      Value<DateTime?> createdTime,
      Value<String?> thumbnailLink,
      required bool isFolder,
      required bool isShared,
      Value<bool> isCached,
      Value<DateTime?> lastSynced,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$FilesTableUpdateCompanionBuilder =
    FilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> mimeType,
      Value<int?> size,
      Value<String?> parentId,
      Value<DateTime?> modifiedTime,
      Value<DateTime?> createdTime,
      Value<String?> thumbnailLink,
      Value<bool> isFolder,
      Value<bool> isShared,
      Value<bool> isCached,
      Value<DateTime?> lastSynced,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$FilesTableFilterComposer extends Composer<_$AppDatabase, $FilesTable> {
  $$FilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedTime => $composableBuilder(
    column: $table.modifiedTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdTime => $composableBuilder(
    column: $table.createdTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailLink => $composableBuilder(
    column: $table.thumbnailLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFolder => $composableBuilder(
    column: $table.isFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCached => $composableBuilder(
    column: $table.isCached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilesTableOrderingComposer
    extends Composer<_$AppDatabase, $FilesTable> {
  $$FilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedTime => $composableBuilder(
    column: $table.modifiedTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdTime => $composableBuilder(
    column: $table.createdTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailLink => $composableBuilder(
    column: $table.thumbnailLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFolder => $composableBuilder(
    column: $table.isFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCached => $composableBuilder(
    column: $table.isCached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilesTable> {
  $$FilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedTime => $composableBuilder(
    column: $table.modifiedTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdTime => $composableBuilder(
    column: $table.createdTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailLink => $composableBuilder(
    column: $table.thumbnailLink,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFolder =>
      $composableBuilder(column: $table.isFolder, builder: (column) => column);

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);

  GeneratedColumn<bool> get isCached =>
      $composableBuilder(column: $table.isCached, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$FilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilesTable,
          File,
          $$FilesTableFilterComposer,
          $$FilesTableOrderingComposer,
          $$FilesTableAnnotationComposer,
          $$FilesTableCreateCompanionBuilder,
          $$FilesTableUpdateCompanionBuilder,
          (File, BaseReferences<_$AppDatabase, $FilesTable, File>),
          File,
          PrefetchHooks Function()
        > {
  $$FilesTableTableManager(_$AppDatabase db, $FilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime?> modifiedTime = const Value.absent(),
                Value<DateTime?> createdTime = const Value.absent(),
                Value<String?> thumbnailLink = const Value.absent(),
                Value<bool> isFolder = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<bool> isCached = const Value.absent(),
                Value<DateTime?> lastSynced = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilesCompanion(
                id: id,
                name: name,
                mimeType: mimeType,
                size: size,
                parentId: parentId,
                modifiedTime: modifiedTime,
                createdTime: createdTime,
                thumbnailLink: thumbnailLink,
                isFolder: isFolder,
                isShared: isShared,
                isCached: isCached,
                lastSynced: lastSynced,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> mimeType = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime?> modifiedTime = const Value.absent(),
                Value<DateTime?> createdTime = const Value.absent(),
                Value<String?> thumbnailLink = const Value.absent(),
                required bool isFolder,
                required bool isShared,
                Value<bool> isCached = const Value.absent(),
                Value<DateTime?> lastSynced = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilesCompanion.insert(
                id: id,
                name: name,
                mimeType: mimeType,
                size: size,
                parentId: parentId,
                modifiedTime: modifiedTime,
                createdTime: createdTime,
                thumbnailLink: thumbnailLink,
                isFolder: isFolder,
                isShared: isShared,
                isCached: isCached,
                lastSynced: lastSynced,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilesTable,
      File,
      $$FilesTableFilterComposer,
      $$FilesTableOrderingComposer,
      $$FilesTableAnnotationComposer,
      $$FilesTableCreateCompanionBuilder,
      $$FilesTableUpdateCompanionBuilder,
      (File, BaseReferences<_$AppDatabase, $FilesTable, File>),
      File,
      PrefetchHooks Function()
    >;
typedef $$CachedPdfsTableCreateCompanionBuilder =
    CachedPdfsCompanion Function({
      required String fileId,
      required Uint8List pdfBytes,
      required DateTime cachedAt,
      required int fileSize,
      Value<int> rowid,
    });
typedef $$CachedPdfsTableUpdateCompanionBuilder =
    CachedPdfsCompanion Function({
      Value<String> fileId,
      Value<Uint8List> pdfBytes,
      Value<DateTime> cachedAt,
      Value<int> fileSize,
      Value<int> rowid,
    });

class $$CachedPdfsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPdfsTable> {
  $$CachedPdfsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get pdfBytes => $composableBuilder(
    column: $table.pdfBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPdfsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPdfsTable> {
  $$CachedPdfsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get pdfBytes => $composableBuilder(
    column: $table.pdfBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPdfsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPdfsTable> {
  $$CachedPdfsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<Uint8List> get pdfBytes =>
      $composableBuilder(column: $table.pdfBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);
}

class $$CachedPdfsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPdfsTable,
          CachedPdf,
          $$CachedPdfsTableFilterComposer,
          $$CachedPdfsTableOrderingComposer,
          $$CachedPdfsTableAnnotationComposer,
          $$CachedPdfsTableCreateCompanionBuilder,
          $$CachedPdfsTableUpdateCompanionBuilder,
          (
            CachedPdf,
            BaseReferences<_$AppDatabase, $CachedPdfsTable, CachedPdf>,
          ),
          CachedPdf,
          PrefetchHooks Function()
        > {
  $$CachedPdfsTableTableManager(_$AppDatabase db, $CachedPdfsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPdfsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPdfsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPdfsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<Uint8List> pdfBytes = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPdfsCompanion(
                fileId: fileId,
                pdfBytes: pdfBytes,
                cachedAt: cachedAt,
                fileSize: fileSize,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required Uint8List pdfBytes,
                required DateTime cachedAt,
                required int fileSize,
                Value<int> rowid = const Value.absent(),
              }) => CachedPdfsCompanion.insert(
                fileId: fileId,
                pdfBytes: pdfBytes,
                cachedAt: cachedAt,
                fileSize: fileSize,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPdfsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPdfsTable,
      CachedPdf,
      $$CachedPdfsTableFilterComposer,
      $$CachedPdfsTableOrderingComposer,
      $$CachedPdfsTableAnnotationComposer,
      $$CachedPdfsTableCreateCompanionBuilder,
      $$CachedPdfsTableUpdateCompanionBuilder,
      (CachedPdf, BaseReferences<_$AppDatabase, $CachedPdfsTable, CachedPdf>),
      CachedPdf,
      PrefetchHooks Function()
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      required String id,
      required String fileId,
      required int pageNumber,
      required String annotationType,
      Value<String?> content,
      Value<String?> position,
      Value<String?> color,
      Value<String?> authorId,
      Value<String?> authorName,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<String> id,
      Value<String> fileId,
      Value<int> pageNumber,
      Value<String> annotationType,
      Value<String?> content,
      Value<String?> position,
      Value<String?> color,
      Value<String?> authorId,
      Value<String?> authorName,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotationType => $composableBuilder(
    column: $table.annotationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotationType => $composableBuilder(
    column: $table.annotationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get annotationType => $composableBuilder(
    column: $table.annotationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (
            Annotation,
            BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation>,
          ),
          Annotation,
          PrefetchHooks Function()
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> annotationType = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> position = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> authorId = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                fileId: fileId,
                pageNumber: pageNumber,
                annotationType: annotationType,
                content: content,
                position: position,
                color: color,
                authorId: authorId,
                authorName: authorName,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fileId,
                required int pageNumber,
                required String annotationType,
                Value<String?> content = const Value.absent(),
                Value<String?> position = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> authorId = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                fileId: fileId,
                pageNumber: pageNumber,
                annotationType: annotationType,
                content: content,
                position: position,
                color: color,
                authorId: authorId,
                authorName: authorName,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (
        Annotation,
        BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation>,
      ),
      Annotation,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String operationType,
      required String resourceType,
      Value<String?> resourceId,
      required String payload,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String> status,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> operationType,
      Value<String> resourceType,
      Value<String?> resourceId,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String> status,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> resourceType = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                operationType: operationType,
                resourceType: resourceType,
                resourceId: resourceId,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationType,
                required String resourceType,
                Value<String?> resourceId = const Value.absent(),
                required String payload,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                operationType: operationType,
                resourceType: resourceType,
                resourceId: resourceId,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FilesTableTableManager get files =>
      $$FilesTableTableManager(_db, _db.files);
  $$CachedPdfsTableTableManager get cachedPdfs =>
      $$CachedPdfsTableTableManager(_db, _db.cachedPdfs);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
