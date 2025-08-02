import 'dart:async';

import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MobileDbCacheManager {
  final Future<Database> _db;

  MobileDbCacheManager() : _db = _getDb();

  @visibleForTesting
  static const tableName = "flutter_cached_images";

  @visibleForTesting
  MobileDbCacheManager.test(this._db);

  static Future<Database> _getDb() async {
    final _dbPath = await _getDatabasePath();

    return openDatabase(
      _dbPath,
      onCreate: createDb,
      onUpgrade: upgradeDb,
      // 1. Initial version
      // 2. Added 'maxAge' number field
      version: 2,
    );
  }

  static Future<String> _getDatabasePath() async =>
      join((await getTemporaryDirectory()).path, "$tableName.db");

  Future<List<CachedObject>?> clear({
    Duration? modifiedBefore,
    required String subDir,
  }) async {
    final db = await _db;

    final millis = getNowTimeFunc()
        .subtract(modifiedBefore ?? Duration.zero)
        .millisecondsSinceEpoch;

    const where = "modifiedAt < ? and fullLocalPath LIKE ?";

    final subDirParam = '%/$subDir/%';

    final data = await db.query(
      tableName,
      where: where,
      whereArgs: [
        millis,
        subDirParam,
      ],
    );

    await db.delete(
      tableName,
      where: where,
      whereArgs: [millis, subDirParam],
    );

    return data.map((e) => CachedObject.fromMap(e)).toList();
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
      modifiedAt INTEGER,
      maxAge INTEGER
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

  @visibleForTesting
  static Future<void> upgradeDb(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute("""
ALTER TABLE $tableName ADD COLUMN maxAge INTEGER;
      """);
    }
  }
}
