import 'dart:async';

import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const _kImageCacheDb = "flutter_cached_images";

String? _cachedDbPath;

// final _cachedAppDirPaths = <String, String>{};
// final _subDir = subDir ?? _kImageCacheDir;

// if (_cachedAppDirPaths.containsKey(_subDir)) {
//   _dirPath = _cachedAppDirPaths[_subDir]!;
// } else {
//   _dirPath = await _getCacheDir(subDir ?? _kImageCacheDir);
//   _cachedAppDirPaths.putIfAbsent(_subDir, () => _dirPath);
// }

// static Future<String> _getCacheDir(String subDir) async {
//   final _dir = await getTemporaryDirectory();
//   return join(_dir.path, subDir);
// }

class MobileDbCacheManager {
  final Database db;

  MobileDbCacheManager._(this.db);

  static Future<MobileDbCacheManager> init([String? subDir]) async {
    final _dbPath = _cachedDbPath ?? await _getDatabasePath();
    _cachedDbPath = _dbPath;

    final db = await openDatabase(
      _dbPath,
      onCreate: _createDb,
      version: 1,
    );

    return MobileDbCacheManager._(db);
  }

  static Future<String> _getDatabasePath() async =>
      join((await getTemporaryDirectory()).path, "$_kImageCacheDb.db");

  Future<void> clear() async {
    await db.delete(_kImageCacheDb);
  }

  Future<void> delete(String id) {
    return db.delete(_kImageCacheDb, where: 'id = ?', whereArgs: [id]);
  }

  Future<CachedObject?> get(String id) async {
    final maps = await db.query(
      _kImageCacheDb,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return CachedObject.fromMap(maps[0]);
  }

  // @visibleForTesting
  // String getFullFilePath(String fileName) {
  //   final _fileName =
  //       fileName.startsWith("/") ? fileName.substring(1) : fileName;
  //   return join(_appDir, _fileName);
  // }

  Future<CachedObject> put(CachedObject cachedObject) async {
    final data = cachedObject.toMap()..remove("rawData");

    await db.insert(
      _kImageCacheDb,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return cachedObject;
  }

  static Future<void> _createDb(Database db, int version) async {
    await db.execute(
      '''
    CREATE TABLE $_kImageCacheDb (
      id TEXT PRIMARY KEY,
      fullLocalPath TEXT,
      uri TEXT,
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

  Future<void> update(String id) async {
    final data = <String, dynamic>{
      "modifiedAt": DateTime.now().millisecondsSinceEpoch
    };

    await db.update(
      _kImageCacheDb,
      data,
      where: "id = ?",
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> dispose() => db.close();
}
