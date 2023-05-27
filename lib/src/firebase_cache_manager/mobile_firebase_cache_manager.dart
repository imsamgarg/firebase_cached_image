import 'dart:io';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/db_cache_manager/mobile_db_cache_manager.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const _kImageCacheDir = "flutter_cached_image";
final _cachedAppDirPaths = <String, String>{};

Future<String> _getLocalDir([String? subDir]) async {
  final _subDir = subDir ?? _kImageCacheDir;
  String _localDir;

  if (_cachedAppDirPaths.containsKey(_subDir)) {
    _localDir = _cachedAppDirPaths[_subDir]!;
  } else {
    final _cacheDir = await getTemporaryDirectory();
    _localDir = join(_cacheDir.path, subDir);
    _cachedAppDirPaths.putIfAbsent(_subDir, () => _localDir);
  }

  await Directory(_localDir).create();

  return _localDir;
}

class FirebaseCacheManager extends BaseFirebaseCacheManager {
  FirebaseCacheManager({super.subDir})
      : _cacheManager = MobileDbCacheManager.init(),
        _cacheDirectoryPath = _getLocalDir(subDir);

  final Future<MobileDbCacheManager> _cacheManager;
  final Future<String> _cacheDirectoryPath;

  @override
  Future<CachedObject> getSingleObject(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
    int maxSize = 10485760,
  }) async {
    final manager = await _cacheManager;
    Uint8List? bytes;

    if (options.source == Source.server) {
      bytes = await firebaseUrl.ref.getData(maxSize);
    }

    final image = await manager.get(firebaseUrl.uniqueId);

    if (image != null) {
      final file = File(await getFullLocalPath(image.id));

      if (file.existsSync()) {
        if (options.checkForMetadataChange) {
          final refreshImageFuture = _refreshCachedFile(
            firebaseUrl,
            manager: manager,
            cachedObject: image,
          );

          if (!options.metadataRefreshInBackground) await refreshImageFuture;
        }

        return image.copyWith(rawData: await file.readAsBytes());
      }
    }

    bytes = await firebaseUrl.ref.getData(maxSize);

    final cachedObject = CachedObject(
      id: firebaseUrl.uniqueId,
      url: firebaseUrl.url.toString(),
      rawData: bytes,
      modifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    manager.put(cachedObject);
    File(await getFullLocalPath(cachedObject.id)).writeAsBytes(bytes!);
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

    /// Refresh cache file in background
    if (options.checkForMetadataChange) {
      final refreshFileFuture = _refreshCachedFile(
        firebaseUrl,
        manager: manager,
        cachedObject: cachedObject,
      );

      if (!options.metadataRefreshInBackground) await refreshFileFuture;
    }

    return getFullLocalPath(firebaseUrl.uniqueId);
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
    final localFilePath = await getFullLocalPath(firebaseUrl.uniqueId);
    await firebaseUrl.ref.writeToFile(File(localFilePath));
    await manager.put(
      CachedObject(
        id: firebaseUrl.uniqueId,
        fullLocalPath: localFilePath,
        url: firebaseUrl.url.toString(),
        modifiedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    return localFilePath;
  }

  @override
  Future<void> clearCache() async {
    final manager = await _cacheManager;
    final dirPath = await _cacheDirectoryPath;

    await Future.wait([
      Directory(dirPath).delete(recursive: true),
      manager.clear(),
    ]);

    await Directory(dirPath).create();
  }

  @override
  Future<void> delete(FirebaseUrl firebaseUrl) async {
    final id = getUniqueId(firebaseUrl.url.toString());
    final localPath = await getFullLocalPath(id);
    final manager = await _cacheManager;

    await Future.wait([
      File(localPath).delete(),
      manager.delete(id),
    ]);
  }

  Future<String> getFullLocalPath(String fileName) async {
    return join(await _cacheDirectoryPath, fileName);
  }

  @override
  Future<bool> isCached(FirebaseUrl firebaseUrl) async {
    final manager = await _cacheManager;

    final cachedObject = await manager.get(firebaseUrl.uniqueId);

    if (cachedObject == null) return false;

    return File(await getFullLocalPath(cachedObject.id)).existsSync();
  }
}
