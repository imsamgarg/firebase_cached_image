import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:firebase_cached_image/src/cloud_storage_manager/native_cloud_storage_manage.dart';
import 'package:firebase_cached_image/src/core/cache_options.dart';
import 'package:firebase_cached_image/src/core/firebase_url.dart';
import 'package:firebase_cached_image/src/core/source.dart';
import 'package:firebase_cached_image/src/db_cache_manager/mobile_db_cache_manager.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/mobile_firebase_cache_manager.dart';
import 'package:firebase_cached_image/src/fs_manager/fs_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../cloud_storage_manager/cloud_storage_manager_test.mocks.dart';

void main() {
  late Database db;
  late MobileDbCacheManager manager;
  late NativeCloudStorageManager cloudStorageManager;
  late FileSystem fs;
  late FsManager fsManager;
  late FirebaseCacheManager cacheManager;
  late Reference ref;

  const subDir = "test";
  const bucket = "bucket";
  const fullPath = "userpic.jpg";

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(inMemoryDatabasePath);
    await MobileDbCacheManager.createDb(db, 1);
    manager = MobileDbCacheManager.test(Future.value(db));
    cloudStorageManager = TestNativeCloudStorageManager();
    fs = MemoryFileSystem.test();
    getTempDir = () async => fs.systemTempDirectory;

    fsManager = FsManager.test(fs, subDir: subDir);
    cacheManager = FirebaseCacheManager.test(
      cacheManager: manager,
      fs: fsManager,
      cloudStorageManager: cloudStorageManager,
    );
  });

  setUp(() {
    ref = MockReference();
    when(ref.fullPath).thenReturn(fullPath);
    when(ref.bucket).thenReturn(bucket);
  });

  //* Test the downloadToCache method
  test("downloadToCache", () async {
    final url = FirebaseUrl.fromReference(ref);
    final bytes = TestNativeCloudStorageManager.bytes;

    final filePath = await cacheManager.downloadToCache(url);

    final file = fs.file(filePath);

    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), equals(bytes));

    final cachedObject = await manager.get(url.uniqueId);

    expect(cachedObject, isNotNull);
    expect(cachedObject!.id, url.uniqueId);
  });

  //* Test the getSingleObject method group with multiple test cases
  group("getSingleObject ", () {
    test("when the source is Source.server", () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = TestNativeCloudStorageManager.bytes;

      when(cloudStorageManager.downloadLatestFile(url))
          .thenAnswer((_) async => bytes);

      final cachedObject = await cacheManager.getSingleObject(
        url,
        options: const CacheOptions(source: Source.server),
      );

      expect(cachedObject.id, url.uniqueId);
      expect(cachedObject.rawData, bytes);
      expect(cachedObject.url, url.url.toString());
      expect(cachedObject.modifiedAt, isNotNull);

      final file = await fsManager.getFile(url.uniqueId);

      //* File should not exist in the cache
      expect(await file.exists(), isFalse);
    });

    //* When the source is Source.cacheServer
    test("when the source is Source.cacheServer", () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = TestNativeCloudStorageManager.bytes;

      when(cloudStorageManager.downloadLatestFile(url))
          .thenAnswer((_) async => bytes);

      final cachedObject = await cacheManager.getSingleObject(
        url,
        // ignore: avoid_redundant_argument_values
        options: const CacheOptions(source: Source.cacheServer),
      );

      expect(cachedObject.id, url.uniqueId);
      expect(cachedObject.rawData, bytes);
      expect(cachedObject.url, url.url.toString());
      expect(cachedObject.modifiedAt, isNotNull);

      final file = await fsManager.getFile(url.uniqueId);

      //* File should exist in the cache
      expect(await file.exists(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));
    });

    //* When the source is Source.cacheServer on first it should download the file on next call it should get the file from the cache
    test(
        "when the source is Source.cacheServer on first it should download the file on next call it should get the file from the cache",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = TestNativeCloudStorageManager.bytes;

      when(cloudStorageManager.downloadLatestFile(url))
          .thenAnswer((_) async => bytes);

      final cachedObject = await cacheManager.getSingleObject(
        url,
        // ignore: avoid_redundant_argument_values
        options: const CacheOptions(source: Source.cacheServer),
      );

      expect(cachedObject.id, url.uniqueId);
      expect(cachedObject.rawData, equals(bytes));
      expect(cachedObject.url, url.url.toString());
      expect(cachedObject.modifiedAt, isNotNull);

      //* On first call it should download the file
      verify(cloudStorageManager.downloadLatestFile(url)).called(1);

      final file = await fsManager.getFile(url.uniqueId);

      //* File should exist in the cache
      expect(await file.exists(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));

      final cachedObject2 = await cacheManager.getSingleObject(
        url,
        // ignore: avoid_redundant_argument_values
        options: const CacheOptions(source: Source.cacheServer),
      );

      //* On next call it should get the file from the cache
      verifyNever(cloudStorageManager.downloadLatestFile(url));
      expect(cachedObject2.id, url.uniqueId);
      expect(cachedObject2.rawData, bytes);
      expect(cachedObject2.url, url.url.toString());
      expect(cachedObject2.modifiedAt, isNotNull);
    });
  });

  tearDown(() async {
    await db.delete(MobileDbCacheManager.tableName);
    await fsManager.deleteAllFiles();
  });

  tearDownAll(() {
    db.close();
  });
}
