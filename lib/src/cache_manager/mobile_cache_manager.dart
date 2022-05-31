import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_object.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const _kImageCacheDir = "flutter_cached_image";
const _kImageCacheDb = "flutter_cached_images";

class CacheManager extends BaseCacheManager {
  late final String _appDir;
  late final Database db;

  @override
  Future<CacheManager> init() async {
    _appDir = await _getCacheDir(_kImageCacheDir);
    await Directory(_appDir).create();

    final _dbPath = join(await getDatabasesPath(), "$_kImageCacheDb.db");

    db = await openDatabase(
      _dbPath,
      onCreate: _createDb,
      version: 1,
    );

    return this;
  }

  @visibleForTesting
  String setAppDir(String dir) => _appDir = dir;

  Future<String> _getCacheDir(String subDir) async {
    final _dir = await getTemporaryDirectory();
    return join(_dir.path, subDir);
  }

  @override
  Future<void> clear() async {
    await db.delete(_kImageCacheDb);
    await Directory(_appDir).delete(recursive: true);
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(_kImageCacheDb, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<CachedObject?> get(String id) async {
    final maps = await db.query(
      _kImageCacheDb,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final image = CachedObject.fromMap(maps[0]);
    late final Uint8List bytes;

    try {
      bytes = await File(getFullFilePath(image.id)).readAsBytes();
      return image.copyWith(rawData: bytes);
    } on FileSystemException catch (_) {
      return null;
    }
  }

  @visibleForTesting
  String getFullFilePath(String fileName) {
    final _fileName =
        fileName.startsWith("/") ? fileName.substring(1) : fileName;
    return join(_appDir, _fileName);
  }

  @override
  Future<CachedObject> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
  }) async {
    final localPath = getFullFilePath(id);

    final _imageForDb = CachedObject(
      id: id,
      fullLocalPath: localPath,
      uri: uri,
      modifiedAt: modifiedAt,
      rawData: bytes,
    );

    final data = _imageForDb.toMap();
    data.remove("rawData");

    await db.insert(
      _kImageCacheDb,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await File(localPath).writeAsBytes(bytes);
    return _imageForDb;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute(
      '''
    CREATE TABLE $_kImageCacheDb (
      id TEXT PRIMARY KEY,
      fullLocalPath TEXT,
      uri TEXT,
      lastAccessedAt INTEGER
      modifiedAt INTEGER
    )
    ''',
    );

    await db.execute(
      '''
CREATE UNIQUE INDEX idx_id
ON $_kImageCacheDb (id);
''',
    );
  }

  @override
  Future<void> update(
    String id, {
    int? modifiedAt,
    int? lastAccessedAt,
    Uint8List? bytes,
  }) async {
    final localPath = getFullFilePath(id);

    final data = <String, dynamic>{};

    if (modifiedAt != null) {
      data.putIfAbsent("modifiedAt", () => modifiedAt);
    }

    if (lastAccessedAt != null) {
      data.putIfAbsent("lastAccessedAt", () => lastAccessedAt);
    }

    await db.update(
      _kImageCacheDb,
      data,
      where: "id = ?",
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (bytes == null) return;
    await File(localPath).writeAsBytes(bytes);
  }
}
