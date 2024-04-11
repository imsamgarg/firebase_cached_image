import 'dart:async';

import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MobileDbCacheManager {
  final Future<Database> _db;

  MobileDbCacheManager.init() : _db = _getDb();

  @visibleForTesting
  static const tableName = "flutter_cached_images";

  @visibleForTesting
  MobileDbCacheManager.test(this._db);

  static Future<Database> _getDb() async {
    final _dbPath = await _getDatabasePath();

    return openDatabase(
      _dbPath,
      onCreate: createDb,
      version: 1,
    );
  }

  static Future<String> _getDatabasePath() async =>
      join((await getTemporaryDirectory()).path, "$tableName.db");

  Future<List<CachedObject>?> clear({Duration? modifiedBefore}) async {
    final db = await _db;
    if (modifiedBefore != null) {
      final millis =
          getNowTimeFunc().subtract(modifiedBefore).millisecondsSinceEpoch;

      final data = await db.query(
        tableName,
        where: "modifiedAt < ?",
        whereArgs: [millis],
      );

      await db.delete(tableName, where: "modifiedAt < ?", whereArgs: [millis]);

      return data.map((e) => CachedObject.fromMap(e)).toList();
    } else {
      await db.delete(tableName);
    }

    return null;
  }

  Future<void> delete(String id) async {
    (await _db).delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<CachedObject?> get(String id) async {
    final db = await _db;
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
    final db = await _db;

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

  Future<void> dispose() async => (await _db).close();

  @visibleForTesting
  late DateTime Function() getNowTimeFunc = getNowTime;

  @visibleForTesting
  DateTime getNowTime() => DateTime.now();
}
