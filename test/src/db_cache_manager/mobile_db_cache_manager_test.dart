import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/db_cache_manager/mobile_db_cache_manager.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

CachedObject _createTempCachedObject(
  String url, [
  int? modifiedAt,
  String? localPath,
]) {
  return CachedObject(
    id: getUniqueId(url),
    url: url,
    fullLocalPath: localPath,
    modifiedAt: modifiedAt ?? DateTime.now().millisecondsSinceEpoch,
  );
}

String _getTempUrl(String fileName) {
  return "gs://bucket123/$fileName";
}

void main() {
  Future<void> _cleanUp(Database db) async =>
      db.delete(MobileDbCacheManager.tableName);

  late final Database db;
  late final MobileDbCacheManager manager;

  Future<CachedObject> putTempCachedObject(
    String fileName, {
    int? modifiedAt,
    String? localPath,
  }) {
    final url = _getTempUrl(fileName);
    return manager.put(_createTempCachedObject(url, modifiedAt, localPath));
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(inMemoryDatabasePath);
    await MobileDbCacheManager.createDb(db, 1);
    manager = MobileDbCacheManager.test(Future.value(db));
  });

  test('cache hit', () async {
    final _dbCachedObject = await putTempCachedObject("fileName");
    final CachedObject? cachedFile = await manager.get(_dbCachedObject.id);

    expect(cachedFile != null, true);
    expect(cachedFile, _dbCachedObject);
  });

  test('properties check', () async {
    const String fileName = "fileName";
    final url = _getTempUrl(fileName);
    final _dbCachedObject = await putTempCachedObject(fileName);

    final CachedObject? cachedFile = await manager.get(_dbCachedObject.id);

    expect(cachedFile != null, true);
    expect(cachedFile, _dbCachedObject);
    expect(cachedFile!.url, url);
    expect(cachedFile.id, getUniqueId(url));
    expect(cachedFile.rawData, null);
  });
  test("cache-miss", () async {
    const String fileName = "fileName";
    final url = _getTempUrl(fileName);
    final id = getUniqueId(url);

    final CachedObject? cachedFile = await manager.get(id);

    expect(cachedFile == null, true);
  });

  test('cache hit and miss 10 objects', () async {
    for (var i = 0; i < 10; i++) {
      final _dbCachedObject = await putTempCachedObject("fileName$i");
      final CachedObject? cachedFile = await manager.get(_dbCachedObject.id);

      expect(cachedFile != null, true);
      expect(cachedFile, _dbCachedObject);
      expect(cachedFile!.rawData, null);
    }

    await _cleanUp(db);

    for (var i = 0; i < 10; i++) {
      final String fileName = "fileName$i";
      final url = _getTempUrl(fileName);
      final id = getUniqueId(url);
      final cachedFile = await manager.get(id);
      expect(cachedFile == null, true);
    }
  });

  test("delete objects", () async {
    // it wont do anything  if id the does not exist
    await manager.delete("id");

    final id = getUniqueId(_getTempUrl("fileName"));
    await putTempCachedObject("fileName");

    var cachedObject = await manager.get(id);
    expect(cachedObject != null, true);

    await manager.delete(id);

    cachedObject = await manager.get(id);
    expect(cachedObject == null, true);

    await manager.delete(id);
  });

  test('updating object using put method', () async {
    final id = getUniqueId(_getTempUrl("fileName"));
    final _dbObject = await putTempCachedObject("fileName");

    var cachedObject = await manager.get(id);

    expect(cachedObject, _dbObject);

    cachedObject = await manager.put(cachedObject!.copyWith(modifiedAt: 2));

    // Only this value should change...
    expect(cachedObject.modifiedAt != _dbObject.modifiedAt, true);

    expect(cachedObject.fullLocalPath, _dbObject.fullLocalPath);
    expect(cachedObject.id, _dbObject.id);
    expect(cachedObject.rawData, _dbObject.rawData);
    expect(cachedObject.url, _dbObject.url);

    /// Will create a new object which is what its supposed to do
    cachedObject = await manager.put(cachedObject.copyWith(id: "new_id"));

    //
    expect(cachedObject.id != _dbObject.id, true);

    final object1 = await manager.get(id);
    final object2 = await manager.get("new_id");

    expect(object1 != null, true);
    expect(object2 != null, true);

    /// Update this to previous value
    cachedObject = await manager.put(_dbObject);

    expect(cachedObject, _dbObject);
  });

  group("clear", () {
    test("objects with modifiedBefore filter", () async {
      final dateTime = DateTime.now();

      manager.getNowTimeFunc = () {
        return dateTime;
      };

      final files = List.generate(
        20,
        (index) {
          return dateTime.subtract(Duration(minutes: index + 1));
        },
      );

      const subDir = "test";

      final objects = await Future.wait(
        files.map(
          (e) => putTempCachedObject(
            "file_$e.jpg",
            modifiedAt: e.millisecondsSinceEpoch,
            localPath: "storage/$subDir/path_$e.jpg",
          ),
        ),
      );

      const modifiedBefore = Duration(minutes: 10);
      final modifiedTime = dateTime.subtract(modifiedBefore);

      final dbDeletedObjects =
          await manager.clear(modifiedBefore: modifiedBefore, subDir: subDir);

      final deletedObjects = objects
          .where(
            (value) => value.modifiedAt < modifiedTime.millisecondsSinceEpoch,
          )
          .toList();

      expect(deletedObjects.length, dbDeletedObjects?.length);

      expect(
        deletedObjects.toSet(),
        dbDeletedObjects?.toSet(),
      );
    });

    test("all objects without modified filter", () async {
      const subDir = "test";
      final objects = await Future.wait(
        List.generate(
          10,
          (index) => putTempCachedObject(
            "file$index.jpg",
            localPath: "storage/$subDir/path$index.jpg",
          ),
        ),
      );

      await manager.clear(subDir: subDir);

      for (final obj in objects) {
        final dbObj = await manager.get(obj.id);

        expect(null, dbObj);
      }
    });

    test("When no objects are there with the given subDir value", () async {
      const subDir = "test";
      final objects = await Future.wait(
        List.generate(
          10,
          (index) => putTempCachedObject(
            "file$index.jpg",
            localPath: "storage/$subDir/path$index.jpg",
          ),
        ),
      );

      final deletedObjects = await manager.clear(subDir: "test2");
      expect(deletedObjects?.length, 0);

      for (final obj in objects) {
        final dbObj = await manager.get(obj.id);

        expect(obj, dbObj);
      }
    });

    //* Test when there are objects with different subDir values
    test("objects with different subDir values and modifiedBefore is null",
        () async {
      final files = List.generate(20, (i) => i);

      const subDir = "test";
      const subDir2 = "test2";

      final objects = await Future.wait(
        files.map(
          (e) => putTempCachedObject(
            "file_$e.jpg",
            localPath: "storage/$subDir/path_$e.jpg",
          ),
        ),
      );

      final objects2 = await Future.wait(
        files.map(
          (e) => putTempCachedObject(
            "file2_$e.jpg",
            localPath: "storage/$subDir2/path_$e.jpg",
          ),
        ),
      );

      final dbDeletedObjects = await manager.clear(subDir: subDir);

      final deletedObjects = objects.toList();

      expect(deletedObjects.length, dbDeletedObjects?.length);

      expect(
        deletedObjects.toSet(),
        dbDeletedObjects?.toSet(),
      );

      final dbDeletedObjects2 = await manager.clear(subDir: subDir2);

      final deletedObjects2 = objects2.toList();

      expect(deletedObjects2.length, dbDeletedObjects2?.length);

      expect(
        deletedObjects2.toSet(),
        dbDeletedObjects2?.toSet(),
      );
    });

    //* Test when there are objects with different subDir values and modifiedBefore is not null

    test("objects with different subDir values and modifiedBefore is not null",
        () async {
      final dateTime = DateTime.now();

      manager.getNowTimeFunc = () {
        return dateTime;
      };

      final files = List.generate(
        20,
        (index) {
          return dateTime.subtract(Duration(minutes: index + 1));
        },
      );

      const subDir = "test";
      const subDir2 = "test2";

      final objects = await Future.wait(
        files.map(
          (e) => putTempCachedObject(
            "file_$e.jpg",
            modifiedAt: e.millisecondsSinceEpoch,
            localPath: "storage/$subDir/path_$e.jpg",
          ),
        ),
      );

      final objects2 = await Future.wait(
        files.map(
          (e) => putTempCachedObject(
            "file2_$e.jpg",
            modifiedAt: e.millisecondsSinceEpoch,
            localPath: "storage/$subDir2/path_$e.jpg",
          ),
        ),
      );

      const modifiedBefore = Duration(minutes: 10);
      final modifiedTime = dateTime.subtract(modifiedBefore);

      final dbDeletedObjects =
          await manager.clear(modifiedBefore: modifiedBefore, subDir: subDir);

      final deletedObjects = objects
          .where(
            (value) => value.modifiedAt < modifiedTime.millisecondsSinceEpoch,
          )
          .toList();

      expect(deletedObjects.length, dbDeletedObjects?.length);

      expect(
        deletedObjects.toSet(),
        dbDeletedObjects?.toSet(),
      );

      final dbDeletedObjects2 =
          await manager.clear(modifiedBefore: modifiedBefore, subDir: subDir2);

      final deletedObjects2 = objects2
          .where(
            (value) => value.modifiedAt < modifiedTime.millisecondsSinceEpoch,
          )
          .toList();

      expect(deletedObjects2.length, dbDeletedObjects2?.length);

      expect(
        deletedObjects2.toSet(),
        dbDeletedObjects2?.toSet(),
      );
    });

    //* Test when there are no objects with the given subDir value
  });

  tearDownAll(() => db.close());
  tearDown(() {
    //Revert back to its original value
    manager.getNowTimeFunc = manager.getNowTime;
    return _cleanUp(db);
  });
}
