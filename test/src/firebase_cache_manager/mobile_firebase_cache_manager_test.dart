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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../cloud_storage_manager/cloud_storage_manager_test.mocks.dart';
import 'mobile_firebase_cache_manager_test.mocks.dart';

@GenerateMocks([NativeCloudStorageManager])
void main() {
  late Database db;
  late MobileDbCacheManager manager;
  late MockNativeCloudStorageManager cloudStorageManager;
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
    cloudStorageManager = MockNativeCloudStorageManager();
    fs = MemoryFileSystem.test();
    getTempDir = () async => fs.systemTempDirectory;

    fsManager = FsManager.test(fs, subDir: subDir);
    cacheManager = FirebaseCacheManager.test(
      cacheManager: manager,
      fs: fsManager,
      cloudStorageManager: cloudStorageManager,
      subDir: subDir,
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
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
      (i) => (i.positionalArguments[1] as File).writeAsBytes(bytes),
    );

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
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

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
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

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
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

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

    //* When the source is Source.cacheServer and checkForMetadataChange is true and the file is not updated
    test(
        "when the source is Source.cacheServer and checkForMetadataChange is true and the file is not updated",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.downloadLatestFile(url)).thenAnswer(
        (_) async => bytes,
      );

      final cachedObject = await cacheManager.getSingleObject(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      expect(cachedObject.id, url.uniqueId);
      expect(cachedObject.rawData, bytes);
      expect(cachedObject.url, url.url.toString());
      expect(cachedObject.modifiedAt, isNotNull);

      verify(cloudStorageManager.downloadLatestFile(url)).called(1);

      when(cloudStorageManager.isUpdated(url, cachedObject.modifiedAt))
          .thenAnswer((_) async => false);

      final cachedObject2 = await cacheManager.getSingleObject(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      //* On next call it should get the file from the cache
      verifyNever(cloudStorageManager.downloadLatestFile(url));
      expect(cachedObject2.modifiedAt, cachedObject.modifiedAt);
      expect(cachedObject2.id, cachedObject.id);
      expect(listEquals(cachedObject.rawData, cachedObject2.rawData), isTrue);
      expect(cachedObject2.url, cachedObject.url);
    });

    //* When the source is Source.cacheServer and checkForMetadataChange is true and the file is updated
    test(
        "when the source is Source.cacheServer and checkForMetadataChange is true and the file is updated",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.downloadLatestFile(url)).thenAnswer(
        (_) async => bytes,
      );

      final cachedObject = await cacheManager.getSingleObject(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      verify(cloudStorageManager.downloadLatestFile(url)).called(1);
      expect(cachedObject.id, url.uniqueId);
      expect(cachedObject.rawData, bytes);
      expect(cachedObject.url, url.url.toString());
      expect(cachedObject.modifiedAt, isNotNull);

      when(cloudStorageManager.isUpdated(url, cachedObject.modifiedAt))
          .thenAnswer((_) async => true);

      final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5, 6]);

      when(cloudStorageManager.downloadLatestFile(url)).thenAnswer(
        (_) async => bytes2,
      );

      final cachedObject2 = await cacheManager.getSingleObject(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      //* On next call it should download the file
      verify(cloudStorageManager.downloadLatestFile(url)).called(1);
      verify(cloudStorageManager.isUpdated(url, cachedObject.modifiedAt))
          .called(1);

      expect(cachedObject2.id, url.uniqueId);
      expect(cachedObject2.rawData, bytes2);
      expect(cachedObject2.url, url.url.toString());
      expect(cachedObject2.modifiedAt, isNotNull);

      //* The modifiedAt should be greater than the previous one
      expect(cachedObject2.modifiedAt > cachedObject.modifiedAt, isTrue);
    });

    tearDown(() async {
      await db.delete(MobileDbCacheManager.tableName);
      await fsManager.deleteAllFiles();
    });
  });

  group("getSingleFile", () {
    //* When the source is Source.server
    test("when the source is Source.server", () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      final filePath = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(source: Source.server),
      );

      final file = fs.file(filePath);

      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(bytes));
    });

    //* When the source is Source.cacheServer on first it should download the file on next call it should get the file from the cache

    test(
        "when the source is Source.cacheServer on first it should download the file on next call it should get the file from the cache",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      final filePath = await cacheManager.getSingleFile(
        url,
        // ignore: avoid_redundant_argument_values
        options: const CacheOptions(source: Source.cacheServer),
      );

      final file = fs.file(filePath);

      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(bytes));
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      final filePath2 = await cacheManager.getSingleFile(
        url,
        // ignore: avoid_redundant_argument_values
        options: const CacheOptions(source: Source.cacheServer),
      );

      verifyNever(cloudStorageManager.writeToFile(url, any));
      expect(filePath2, equals(filePath));
    });

    //* When the source is Source.cacheServer and checkForMetadataChange is true and the file is not updated

    test(
        "when the source is Source.cacheServer and checkForMetadataChange is true and the file is not updated",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      final filePath = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      final file = fs.file(filePath);

      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(bytes));
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      when(cloudStorageManager.isUpdated(url, any))
          .thenAnswer((_) async => false);

      final filePath2 = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      verifyNever(cloudStorageManager.writeToFile(url, any));
      expect(filePath2, equals(filePath));
    });

    //* When the source is Source.cacheServer and checkForMetadataChange is true and the file is updated

    test(
        "when the source is Source.cacheServer and checkForMetadataChange is true and the file is updated",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      final filePath = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      final file = fs.file(filePath);
      final previousFileStat = file.statSync();

      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(bytes));
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      when(cloudStorageManager.isUpdated(url, any))
          .thenAnswer((_) async => true);

      final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5, 6]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async =>
            (inv.positionalArguments[1] as File).writeAsBytes(bytes2),
      );

      final filePath2 = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      expect(filePath2, filePath);
      expect(
        previousFileStat.modified.isBefore(file.statSync().modified),
        isTrue,
      );
      expect(await file.readAsBytes(), equals(bytes2));
    });

    //* When the source is Source.cacheServer and db has the file but the file is not present in the cache
    test(
        "when the source is Source.cacheServer and db has the file but the file is not present in the cache",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      final filePath = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      final file = fs.file(filePath);

      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(bytes));
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      final cachedObject = await manager.get(url.uniqueId);

      expect(cachedObject, isNotNull);

      await fsManager.deleteAllFiles();

      final filePath2 = await cacheManager.getSingleFile(
        url,
        options: const CacheOptions(
          // ignore: avoid_redundant_argument_values
          source: Source.cacheServer,
          checkForMetadataChange: true,
        ),
      );

      final file2 = fs.file(filePath2);

      expect(await file2.exists(), isTrue);
      expect(await file2.readAsBytes(), equals(bytes));
      verify(cloudStorageManager.writeToFile(url, any)).called(1);
    });

    tearDown(() async {
      await db.delete(MobileDbCacheManager.tableName);
      await fsManager.deleteAllFiles();
    });
  });

  //* Test the preCacheFile method
  group("preCacheFile", () {
    test("when file is not present in the cache it should download latest file",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      await cacheManager.preCacheFile(url);
      verify(cloudStorageManager.writeToFile(url, any)).called(1);
    });

    //* When the file is present in the cache
    test("when file is present in the cache it should not download the file",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      await cacheManager.preCacheFile(url);
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      await cacheManager.preCacheFile(url);
      verifyNever(cloudStorageManager.writeToFile(url, any));
    });
  });

  group("refreshCachedFile", () {
    //* When the file is not present in the cache
    test(
        "when the file is not present in the cache it should download the file",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      await cacheManager.refreshCachedFile(url);

      verify(cloudStorageManager.writeToFile(url, any)).called(1);
    });

    //* When the file is present in the cache but not updated on the server
    test(
        "when the file is present in the cache but not updated on the server it should not download the file",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      await cacheManager.preCacheFile(url);
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      when(cloudStorageManager.isUpdated(url, any))
          .thenAnswer((_) async => false);

      await cacheManager.refreshCachedFile(url);

      verifyNever(cloudStorageManager.writeToFile(url, any));
    });

    //* When the file is present in the cache and updated on the server
    test(
        "when the file is present in the cache and updated on the server it should download the file",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as File).writeAsBytes(bytes),
      );

      await cacheManager.preCacheFile(url);
      verify(cloudStorageManager.writeToFile(url, any)).called(1);

      when(cloudStorageManager.isUpdated(url, any))
          .thenAnswer((_) async => true);

      final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5, 6]);

      when(cloudStorageManager.writeToFile(url, any)).thenAnswer(
        (inv) async =>
            (inv.positionalArguments[1] as File).writeAsBytes(bytes2),
      );

      await cacheManager.refreshCachedFile(url);

      verify(cloudStorageManager.writeToFile(url, any)).called(1);
    });

    tearDown(() async {
      await db.delete(MobileDbCacheManager.tableName);
      await fsManager.deleteAllFiles();
    });
  });

  //* Test the isCached method
  test("isCached", () async {
    final url = FirebaseUrl.fromReference(ref);
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    when(cloudStorageManager.downloadLatestFile(url)).thenAnswer(
      (_) async => bytes,
    );

    final isCached = await cacheManager.isCached(url);

    expect(isCached, isFalse);

    await cacheManager.getSingleObject(url);

    final isCached2 = await cacheManager.isCached(url);

    expect(isCached2, isTrue);
  });

  //* Test the delete method
  test("delete", () async {
    final url = FirebaseUrl.fromReference(ref);
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    when(cloudStorageManager.downloadLatestFile(url)).thenAnswer(
      (_) async => bytes,
    );

    await cacheManager.getSingleObject(url);

    final isCached = await cacheManager.isCached(url);

    expect(isCached, isTrue);

    await cacheManager.delete(url);

    final isCached2 = await cacheManager.isCached(url);

    expect(isCached2, isFalse);
  });

  group("copyToCache", () {
    //* Test when the file is not present in the cache
    test("when the file is not present in the cache", () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final tempFile = fs.file("temp.jpg");
      tempFile.writeAsBytesSync(bytes);

      final filePath = await cacheManager.copyToCache(url, tempFile.path);

      final file = fs.file(filePath);

      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));
    });

    //* Test when the file is present in the cache

    test("when the file is present in the cache", () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final tempFile = fs.file("temp.jpg");
      tempFile.writeAsBytesSync(bytes);

      final filePath = await cacheManager.copyToCache(url, tempFile.path);

      final file = fs.file(filePath);
      final fileStats = file.statSync();

      final filePath2 = await cacheManager.copyToCache(url, tempFile.path);

      final file2 = fs.file(filePath2);
      final fileStats2 = file2.statSync();

      expect(filePath2, filePath);
      // File should not be modified
      expect(fileStats2.modified, fileStats.modified);
    });

    //* Test after copying the file to the cache [getSingleFile] should return the file from the cache
    test(
        "after copying the file to the cache getSingleFile should return the file from the cache",
        () async {
      final url = FirebaseUrl.fromReference(ref);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final tempFile = fs.file("temp.jpg");
      tempFile.writeAsBytesSync(bytes);

      final filePath = await cacheManager.copyToCache(url, tempFile.path);

      final filePath2 = await cacheManager.getSingleFile(
        url,
      );

      verifyNever(cloudStorageManager.writeToFile(url, any));
      expect(filePath2, filePath);
    });
  });

  group("clearCache", () {
    //* Test when the clearCache will remove every file from the cache

    test("when the clearCache will remove every file from the cache", () async {
      final url1 = MockFirebaseUrl();
      when(url1.uniqueId).thenReturn("1.jpg");
      when(url1.url).thenReturn(Uri.parse("www.google.com"));
      final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5]);

      final url2 = MockFirebaseUrl();
      when(url2.uniqueId).thenReturn("2.jpg");
      when(url2.url).thenReturn(Uri.parse("www.google.com"));
      final bytes2 = Uint8List.fromList([6, 7, 8, 9, 10]);

      final url3 = MockFirebaseUrl();
      when(url3.uniqueId).thenReturn("3.jpg");
      when(url3.url).thenReturn(Uri.parse("www.google.com"));
      final bytes3 = Uint8List.fromList([11, 12, 13, 14, 15]);

      when(cloudStorageManager.downloadLatestFile(url1)).thenAnswer(
        (_) async => bytes1,
      );

      when(cloudStorageManager.downloadLatestFile(url2)).thenAnswer(
        (_) async => bytes2,
      );

      when(cloudStorageManager.downloadLatestFile(url3)).thenAnswer(
        (_) async => bytes3,
      );

      await cacheManager.getSingleObject(url1);
      await cacheManager.getSingleObject(url2);
      await cacheManager.getSingleObject(url3);

      final isCached1 = await cacheManager.isCached(url1);
      final isCached2 = await cacheManager.isCached(url2);
      final isCached3 = await cacheManager.isCached(url3);

      expect(isCached1, isTrue);
      expect(isCached2, isTrue);
      expect(isCached3, isTrue);

      await cacheManager.clearCache();

      final isCached1AfterClear = await cacheManager.isCached(url1);
      final isCached2AfterClear = await cacheManager.isCached(url2);
      final isCached3AfterClear = await cacheManager.isCached(url3);

      expect(isCached1AfterClear, isFalse);
      expect(isCached2AfterClear, isFalse);
      expect(isCached3AfterClear, isFalse);
    });

    //* Test when the modifiedBefore is provided
    test("when the modifiedBefore is provided", () async {
      final url1 = MockFirebaseUrl();
      when(url1.uniqueId).thenReturn("1.jpg");
      when(url1.url).thenReturn(Uri.parse("www.google.com"));
      final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5]);

      final url2 = MockFirebaseUrl();
      when(url2.uniqueId).thenReturn("2.jpg");
      when(url2.url).thenReturn(Uri.parse("www.google.com"));
      final bytes2 = Uint8List.fromList([6, 7, 8, 9, 10]);

      final url3 = MockFirebaseUrl();
      when(url3.uniqueId).thenReturn("3.jpg");
      when(url3.url).thenReturn(Uri.parse("www.google.com"));
      final bytes3 = Uint8List.fromList([11, 12, 13, 14, 15]);

      when(cloudStorageManager.downloadLatestFile(url1)).thenAnswer(
        (_) async => bytes1,
      );

      when(cloudStorageManager.downloadLatestFile(url2)).thenAnswer(
        (_) async => bytes2,
      );

      when(cloudStorageManager.downloadLatestFile(url3)).thenAnswer(
        (_) async => bytes3,
      );

      final nowTime = DateTime.now();

      manager.getNowTimeFunc = () => nowTime;

      cacheManager.getNowTimeFunc =
          () => nowTime.subtract(const Duration(seconds: 10));
      await cacheManager.getSingleObject(url1);

      cacheManager.getNowTimeFunc =
          () => nowTime.subtract(const Duration(seconds: 5));
      await cacheManager.getSingleObject(url2);

      cacheManager.getNowTimeFunc =
          () => nowTime.subtract(const Duration(seconds: 1));
      await cacheManager.getSingleObject(url3);

      final isCached1 = await cacheManager.isCached(url1);
      final isCached2 = await cacheManager.isCached(url2);
      final isCached3 = await cacheManager.isCached(url3);

      expect(isCached1, isTrue);
      expect(isCached2, isTrue);
      expect(isCached3, isTrue);

      await cacheManager.clearCache(modifiedBefore: const Duration(seconds: 5));

      final isCached1AfterClear = await cacheManager.isCached(url1);
      final isCached2AfterClear = await cacheManager.isCached(url2);
      final isCached3AfterClear = await cacheManager.isCached(url3);

      expect(isCached1AfterClear, isFalse);
      expect(isCached2AfterClear, isTrue);
      expect(isCached3AfterClear, isTrue);
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
