import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/cloud_storage_manager/native_cloud_storage_manage.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/db_cache_manager/mobile_db_cache_manager.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:firebase_cached_image/src/fs_manager/fs_manager.dart';
import 'package:flutter/foundation.dart';

class FirebaseCacheManager extends BaseFirebaseCacheManager {
  FirebaseCacheManager({super.subDir})
      : _cacheManager = MobileDbCacheManager(),
        _fs = FsManager(subDir: subDir ?? kDefaultImageCacheDir),
        _cloudStorageManager = NativeCloudStorageManager();

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
        modifiedAt: DateTime.now().millisecondsSinceEpoch,
        rawData: bytes,
      );
    }

    final image = await _cacheManager.get(firebaseUrl.uniqueId);

    if (image != null) {
      if (file.existsSync()) {
        if (options.checkForMetadataChange) {
          await _refreshCachedFile(
            firebaseUrl,
            cachedObject: image,
          );
        }

        return image.copyWith(rawData: await file.readAsBytes());
      }
    }

    bytes = await _cloudStorageManager.downloadLatestFile(firebaseUrl, maxSize);

    final cachedObject = CachedObject(
      id: firebaseUrl.uniqueId,
      url: firebaseUrl.url.toString(),
      rawData: bytes,
      fullLocalPath: file.path,
      modifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _cacheManager.put(cachedObject);
    file.writeAsBytes(bytes!);
    return cachedObject;
  }

  @override
  Future<String> getSingleFile(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
  }) async {
    if (options.source == Source.server) {
      return _downloadToCache(firebaseUrl);
    }

    final cachedObject = await _cacheManager.get(firebaseUrl.uniqueId);
    if (cachedObject == null) {
      return _downloadToCache(firebaseUrl);
    }

    final file = await _fs.getFile(firebaseUrl.uniqueId);
    if (!file.existsSync()) {
      return _downloadToCache(firebaseUrl);
    }

    /// Refresh cache file in background
    if (options.checkForMetadataChange) {
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
      await _downloadToCache(firebaseUrl);
      return;
    }

    final isUpdated = await _cloudStorageManager.isUpdated(
      firebaseUrl,
      _cachedObject.modifiedAt,
    );

    if (isUpdated) {
      await _downloadToCache(firebaseUrl);
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

    await _downloadToCache(firebaseUrl);
  }

  Future<String> _downloadToCache(FirebaseUrl firebaseUrl) async {
    final file = await _fs.getFile(firebaseUrl.uniqueId);
    await _cloudStorageManager.writeToFile(firebaseUrl, file);
    await _cacheManager.put(
      CachedObject(
        id: firebaseUrl.uniqueId,
        fullLocalPath: file.path,
        url: firebaseUrl.url.toString(),
        modifiedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    return file.path;
  }

  @override
  Future<void> clearCache({
    Duration? modifiedBefore,
  }) async {
    if (modifiedBefore == null) {
      await Future.wait([
        _fs.deleteAllFiles(),

        // Todo. implement a way to only delete rows with subDir equal to this [subDir]
        //
        // It will clear the entire database table that we don't want
        // manager.clear(),
      ]);

      return;
    }

    final paths = await _cacheManager.clear(modifiedBefore: modifiedBefore);
    final _futures = paths!.map((e) => _fs.deleteFile(e.id)).toList();

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
}
