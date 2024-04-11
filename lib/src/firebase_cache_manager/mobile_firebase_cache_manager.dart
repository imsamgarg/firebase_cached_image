import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/db_cache_manager/mobile_db_cache_manager.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:firebase_cached_image/src/fs_manager/fs_manager.dart';
import 'package:flutter/foundation.dart';

class FirebaseCacheManager extends BaseFirebaseCacheManager {
  FirebaseCacheManager({super.subDir})
      : _cacheManager = SynchronousFuture(MobileDbCacheManager.init()),
        _fs = FsManager(subDir: subDir ?? kDefaultImageCacheDir);

  final Future<MobileDbCacheManager> _cacheManager;
  final FsManager _fs;

  @override
  Future<CachedObject> getSingleObject(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
    int maxSize = 10485760,
  }) async {
    final file = await _fs.getFile(firebaseUrl.uniqueId);

    final manager = await _cacheManager;
    Uint8List? bytes;

    if (options.source == Source.server) {
      bytes = await firebaseUrl.ref.getData(maxSize);

      return CachedObject(
        id: firebaseUrl.uniqueId,
        url: firebaseUrl.url.toString(),
        modifiedAt: DateTime.now().millisecondsSinceEpoch,
        rawData: bytes,
      );
    }

    final image = await manager.get(firebaseUrl.uniqueId);

    if (image != null) {
      if (file.existsSync()) {
        if (options.checkForMetadataChange) {
          await _refreshCachedFile(
            firebaseUrl,
            manager: manager,
            cachedObject: image,
          );
        }

        return image.copyWith(rawData: await file.readAsBytes());
      }
    }

    bytes = await firebaseUrl.ref.getData(maxSize);

    final cachedObject = CachedObject(
      id: firebaseUrl.uniqueId,
      url: firebaseUrl.url.toString(),
      rawData: bytes,
      fullLocalPath: file.path,
      modifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    manager.put(cachedObject);
    file.writeAsBytes(bytes!);
    return cachedObject;
  }

  @override
  Future<String> getSingleFile(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
  }) async {
    final manager = await _cacheManager;

    if (options.source == Source.server) {
      return _downloadToCache(firebaseUrl, manager: manager);
    }

    final cachedObject = await manager.get(firebaseUrl.uniqueId);
    if (cachedObject == null) {
      return _downloadToCache(firebaseUrl, manager: manager);
    }

    final file = await _fs.getFile(firebaseUrl.uniqueId);
    if (!file.existsSync()) {
      return _downloadToCache(firebaseUrl, manager: manager);
    }

    /// Refresh cache file in background
    if (options.checkForMetadataChange) {
      await _refreshCachedFile(
        firebaseUrl,
        manager: manager,
        cachedObject: cachedObject,
      );
    }

    return file.path;
  }

  Future<void> _refreshCachedFile(
    FirebaseUrl firebaseUrl, {
    required MobileDbCacheManager manager,
    CachedObject? cachedObject,
  }) async {
    final _cachedObject =
        cachedObject ?? await manager.get(firebaseUrl.uniqueId);

    if (_cachedObject == null) {
      await _downloadToCache(firebaseUrl, manager: manager);
      return;
    }

    final metadata = await firebaseUrl.ref.getMetadata();

    if ((metadata.updated?.millisecondsSinceEpoch ?? 0) >
        _cachedObject.modifiedAt) {
      await _downloadToCache(firebaseUrl, manager: manager);
    }
  }

  @override
  Future<void> refreshCachedFile(FirebaseUrl firebaseUrl) async {
    final manager = await Future.value(_cacheManager);
    return _refreshCachedFile(firebaseUrl, manager: manager);
  }

  @override
  Future<void> preCacheFile(FirebaseUrl firebaseUrl) async {
    final manager = await _cacheManager;

    final cachedObject = await manager.get(firebaseUrl.uniqueId);
    if (cachedObject != null) return;

    await _downloadToCache(firebaseUrl, manager: manager);
  }

  Future<String> _downloadToCache(
    FirebaseUrl firebaseUrl, {
    required MobileDbCacheManager manager,
  }) async {
    final file = await _fs.getFile(firebaseUrl.uniqueId);
    await firebaseUrl.ref.writeToFile(file);
    await manager.put(
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
    final manager = await _cacheManager;

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

    final paths = await manager.clear(modifiedBefore: modifiedBefore);
    final _futures = paths!.map((e) => _fs.deleteFile(e.id)).toList();

    await Future.wait(_futures);
  }

  @override
  Future<void> delete(FirebaseUrl firebaseUrl) async {
    final manager = await _cacheManager;

    await Future.wait([
      _fs.deleteFile(firebaseUrl.uniqueId),
      manager.delete(firebaseUrl.uniqueId),
    ]);
  }

  @override
  Future<bool> isCached(FirebaseUrl firebaseUrl) async {
    final manager = await _cacheManager;

    final cachedObject = await manager.get(firebaseUrl.uniqueId);

    if (cachedObject == null) return false;

    return _fs.fileExists(cachedObject.id);
  }
}
