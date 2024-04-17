import 'dart:async';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/cloud_storage_manager/native_cloud_storage_manage.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/db_cache_manager/mobile_db_cache_manager.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:firebase_cached_image/src/fs_manager/fs_manager.dart';
import 'package:flutter/foundation.dart';

class FirebaseCacheManager extends BaseFirebaseCacheManager {
  final String _subDir;

  FirebaseCacheManager({super.subDir, super.encryption})
      : _cacheManager = MobileDbCacheManager(),
        _fs = FsManager(subDir: subDir ?? kDefaultImageCacheDir),
        _subDir = subDir ?? kDefaultImageCacheDir,
        _cloudStorageManager = NativeCloudStorageManager();

  @visibleForTesting
  FirebaseCacheManager.test({
    required MobileDbCacheManager cacheManager,
    required FsManager fs,
    required NativeCloudStorageManager cloudStorageManager,
    required String subDir,
    super.encryption,
  })  : _cacheManager = cacheManager,
        _fs = fs,
        _subDir = subDir,
        _cloudStorageManager = cloudStorageManager;

  final MobileDbCacheManager _cacheManager;
  final NativeCloudStorageManager _cloudStorageManager;
  final FsManager _fs;

  @override
  Future<CachedObject> getSingleObject(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
    int maxSize = 10485760,
  }) async {
    final file = await _fs.getFile(firebaseUrl.uniqueId);

    Uint8List? bytes;

    if (options.source == Source.server) {
      bytes =
          await _cloudStorageManager.downloadLatestFile(firebaseUrl, maxSize);

      return CachedObject(
        id: firebaseUrl.uniqueId,
        url: firebaseUrl.url.toString(),
        modifiedAt: getNowTimeFunc().millisecondsSinceEpoch,
        rawData: bytes,
      );
    }

    final image = await _cacheManager.get(firebaseUrl.uniqueId);

    if (image != null) {
      if (file.existsSync()) {
        if (!options.checkIfFileUpdatedOnServer) {
          final data = await file.readAsBytes();

          return image.copyWith(rawData: await getDecryptedBytes(data));
        }

        final isUpdated = await _cloudStorageManager.isUpdated(
          firebaseUrl,
          image.modifiedAt,
        );

        if (!isUpdated) {
          final data = await file.readAsBytes();

          return image.copyWith(rawData: await getDecryptedBytes(data));
        }
      }
    }

    bytes = await _cloudStorageManager.downloadLatestFile(firebaseUrl, maxSize);

    final cachedObject = CachedObject(
      id: firebaseUrl.uniqueId,
      url: firebaseUrl.url.toString(),
      rawData: bytes,
      fullLocalPath: file.path,
      modifiedAt: getNowTimeFunc().millisecondsSinceEpoch,
    );

    final encryptedBytes = await getEncryptedBytes(bytes!);

    await Future.wait([
      file.writeAsBytes(encryptedBytes),
      _cacheManager.put(cachedObject),
    ]);

    return cachedObject;
  }

  @override
  Future<String> getSingleFile(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
  }) async {
    if (options.source == Source.server) {
      return downloadToCache(firebaseUrl);
    }

    final cachedObject = await _cacheManager.get(firebaseUrl.uniqueId);
    if (cachedObject == null) {
      return downloadToCache(firebaseUrl);
    }

    final file = await _fs.getFile(firebaseUrl.uniqueId);
    if (!file.existsSync()) {
      return downloadToCache(firebaseUrl);
    }

    /// Refresh cache file in background
    if (options.checkIfFileUpdatedOnServer) {
      await _refreshCachedFile(
        firebaseUrl,
        cachedObject: cachedObject,
      );
    }

    return file.path;
  }

  Future<void> _refreshCachedFile(
    FirebaseUrl firebaseUrl, {
    CachedObject? cachedObject,
  }) async {
    final _cachedObject =
        cachedObject ?? await _cacheManager.get(firebaseUrl.uniqueId);

    if (_cachedObject == null) {
      await downloadToCache(firebaseUrl);
      return;
    }

    final isUpdated = await _cloudStorageManager.isUpdated(
      firebaseUrl,
      _cachedObject.modifiedAt,
    );

    if (isUpdated) {
      await downloadToCache(firebaseUrl);
    }
  }

  @override
  Future<void> refreshCachedFile(FirebaseUrl firebaseUrl) {
    return _refreshCachedFile(firebaseUrl);
  }

  @override
  Future<void> preCacheFile(FirebaseUrl firebaseUrl) async {
    final cachedObject = await _cacheManager.get(firebaseUrl.uniqueId);
    if (cachedObject != null) return;

    await downloadToCache(firebaseUrl);
  }

  @visibleForTesting
  Future<String> downloadToCache(FirebaseUrl firebaseUrl) async {
    final file = await _fs.getFile(firebaseUrl.uniqueId);

    /// If encryption is enabled, download the file and encrypt it before saving to cache.
    if (encryption != null) {
      final bytes = await _cloudStorageManager.downloadLatestFile(firebaseUrl);

      final encryptedBytes = await getEncryptedBytes(bytes!);

      await Future.wait([
        file.writeAsBytes(encryptedBytes),
        _cacheManager.put(
          CachedObject(
            id: firebaseUrl.uniqueId,
            fullLocalPath: file.path,
            url: firebaseUrl.url.toString(),
            modifiedAt: getNowTimeFunc().millisecondsSinceEpoch,
          ),
        ),
      ]);

      return file.path;
    }

    await Future.wait([
      _cloudStorageManager.writeToFile(firebaseUrl, file),
      _cacheManager.put(
        CachedObject(
          id: firebaseUrl.uniqueId,
          fullLocalPath: file.path,
          url: firebaseUrl.url.toString(),
          modifiedAt: getNowTimeFunc().millisecondsSinceEpoch,
        ),
      ),
    ]);

    return file.path;
  }

  @override
  Future<void> clearCache({
    Duration? modifiedBefore,
  }) async {
    if (modifiedBefore == null) {
      await Future.wait([
        _fs.deleteAllFiles(),
        _cacheManager.clear(subDir: _subDir),
      ]);

      return;
    }

    final paths = await _cacheManager.clear(
      modifiedBefore: modifiedBefore,
      subDir: _subDir,
    );

    final _futures = paths!
        .map((e) => _fs.deleteFile(e.id).catchError(_digestError))
        .toList();

    await Future.wait(_futures);
  }

  @override
  Future<void> delete(FirebaseUrl firebaseUrl) {
    return Future.wait([
      _fs.deleteFile(firebaseUrl.uniqueId),
      _cacheManager.delete(firebaseUrl.uniqueId),
    ]);
  }

  @override
  Future<bool> isCached(FirebaseUrl firebaseUrl) async {
    final cachedObject = await _cacheManager.get(firebaseUrl.uniqueId);

    if (cachedObject == null) return false;

    return _fs.fileExists(cachedObject.id);
  }

  @override
  Future<String> copyToCache(FirebaseUrl firebaseUrl, String filePath) async {
    final file = await _fs.getFile(firebaseUrl.uniqueId);

    if (file.existsSync()) return file.path;

    /// If encryption is enabled, read the file contents, encrypt it and write it.
    if (encryption != null) {
      final bytes = await _fs.file(filePath).readAsBytes();

      final encryptedBytes = await getEncryptedBytes(bytes);

      await Future.wait([
        file.writeAsBytes(encryptedBytes),
        _cacheManager.put(
          CachedObject(
            id: firebaseUrl.uniqueId,
            fullLocalPath: file.path,
            url: firebaseUrl.url.toString(),
            modifiedAt: getNowTimeFunc().millisecondsSinceEpoch,
          ),
        ),
      ]);

      return file.path;
    }

    await Future.wait([
      _fs.file(filePath).copy(file.path),
      _cacheManager.put(
        CachedObject(
          id: firebaseUrl.uniqueId,
          fullLocalPath: file.path,
          url: firebaseUrl.url.toString(),
          modifiedAt: getNowTimeFunc().millisecondsSinceEpoch,
        ),
      ),
    ]);

    return file.path;
  }

  void _digestError(Object error, StackTrace stackTrace) {
    //Do nothing for now
  }

  @visibleForTesting
  FutureOr<Uint8List> getDecryptedBytes(Uint8List data) {
    return encryption?.decrypt(data) ?? data;
  }

  @visibleForTesting
  FutureOr<Uint8List> getEncryptedBytes(Uint8List data) {
    return encryption?.encrypt(data) ?? data;
  }

  @visibleForTesting
  late DateTime Function() getNowTimeFunc = getNowTime;

  @visibleForTesting
  DateTime getNowTime() => DateTime.now();
}
