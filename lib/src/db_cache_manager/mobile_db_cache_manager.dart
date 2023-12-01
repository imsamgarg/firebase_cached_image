import 'dart:async';

import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

String? _cachedDbPath;

class MobileDbCacheManager {
  final Database db;

  MobileDbCacheManager._(this.db);

  @visibleForTesting
  static const tableName = "flutter_cached_images";

  @visibleForTesting
  MobileDbCacheManager.test(this.db);

  static Future<MobileDbCacheManager> init([String? subDir]) async {
    final _dbPath = _cachedDbPath ?? await _getDatabasePath();
    _cachedDbPath = _dbPath;

    final db = await openDatabase(
      _dbPath,
      onCreate: createDb,
      version: 1,
    );

    return MobileDbCacheManager._(db);
  }

  static Future<String> _getDatabasePath() async =>
      join((await getTemporaryDirectory()).path, "$tableName.db");

  Future<List<String>?> clear({Duration? modifiedBefore}) async {
    if (modifiedBefore != null) {
      final millis =
          getNowTimeFunc().subtract(modifiedBefore).millisecondsSinceEpoch;

      final data = await db.query(
        tableName,
        where: "modifiedAt < ?",
        whereArgs: [millis],
        columns: ["fullLocalPath"],
      );

      await db.delete(tableName, where: "modifiedAt < ?", whereArgs: [millis]);

      return data.map((e) => e['fullLocalPath']! as String).toList();
    } else {
      await db.delete(tableName);
    }

    return null;
  }

  Future<void> delete(String id) {
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<CachedObject?> get(String id) async {
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return CachedObject.fromMap(maps[0]);
  }

  /// This method is used for both insertion and updation...
  Future<CachedObject> put(CachedObject cachedObject) async {
    final data = cachedObject.toMap()..remove("rawData");

    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return cachedObject;
  }

  @visibleForTesting
  static Future<void> createDb(Database db, int version) async {
    await db.execute(
      '''
    CREATE TABLE $tableName (
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
ON $tableName (id);
''',
    );
  }

  Future<void> dispose() => db.close();

  @visibleForTesting
  late DateTime Function() getNowTimeFunc = getNowTime;

  @visibleForTesting
  DateTime getNowTime() => DateTime.now();
}
