import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
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
    Directory(_appDir).deleteSync(recursive: true);
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(_kImageCacheDb, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<CachedImage?> get(String id) async {
    final maps = await db.query(
      _kImageCacheDb,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return CachedImage.fromMap(maps[0]);
  }

  @visibleForTesting
  String getFullFilePath(String fileName) {
    final _fileName =
        fileName.startsWith("/") ? fileName.substring(1) : fileName;
    return join(_appDir, _fileName);
  }

  @override
  Future<void> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
    int? cachedAt,
  }) async {
    final localPath = getFullFilePath(id);

    final _imageForDb = CachedImage(
      id: id,
      fullLocalPath: localPath,
      uri: uri,
      modifiedAt: modifiedAt,
      cachedAt: cachedAt,
    );
    final data = _imageForDb.toMap();
    data.remove("rawData");

    await db.insert(
      _kImageCacheDb,
      data,
    );

    File(localPath).writeAsBytesSync(bytes);
  }

  Future<void> _createDb(Database db, int version) async {
    return db.execute(
      '''
    CREATE TABLE $_kImageCacheDb (
      id TEXT PRIMARY KEY,
      fullLocalPath TEXT,
      uri TEXT,
      cachedAt INTEGER,
      modifiedAt INTEGER,
    )
    ''',
    );
  }

  @override
  Future<void> update(
    String id, {
    required String uri,
    int? modifiedAt,
    Uint8List? bytes,
    int? cachedAt,
  }) async {
    final localPath = getFullFilePath(id);

    final data = <String, dynamic>{"uri": uri, "fullLocalPath": localPath};

    if (modifiedAt != null) {
      data.putIfAbsent("modifiedAt", () => modifiedAt);
    }

    if (cachedAt != null) {
      data.putIfAbsent("cachedAt", () => cachedAt);
    }

    await db.update(
      _kImageCacheDb,
      data,
      where: "id = ?",
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (bytes == null) return;

    File(localPath).writeAsBytesSync(bytes);
  }
}
