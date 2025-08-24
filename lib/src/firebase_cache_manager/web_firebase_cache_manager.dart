import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/db_cache_manager/web_db_cache_manager.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseCacheManager extends BaseFirebaseCacheManager {
  late final WebDbCacheManager _webDbCacheManager = WebDbCacheManager();

  FirebaseCacheManager({super.subDir});

  @override
  Future<void> clearCache({Duration? modifiedBefore}) =>
      _webDbCacheManager.clear(subDir: subDir);

  @override
  Future<void> delete(FirebaseUrl firebaseUrl) =>
      _webDbCacheManager.delete(firebaseUrl.uniqueId);

  @override
  Future<String> getSingleFile(
    FirebaseUrl firebaseUrl, {
    Reference? ref,
    CacheOptions options = const CacheOptions(),
  }) {
    throw UnsupportedError("Not Supported On Web");
  }

  @override
  Future<void> preCacheFile(FirebaseUrl firebaseUrl) =>
      _fetchFromServer(firebaseUrl).then((value) => _saveToCache(value));

  @override
  Future<void> refreshCachedFile(FirebaseUrl firebaseUrl) => _refreshFile(
        const CacheOptions(checkIfFileUpdatedOnServer: true),
        firebaseUrl,
      ).then((value) => _saveToCache(value));

  @override
  Future<CachedObject> getSingleObject(
    FirebaseUrl firebaseUrl, {
    CacheOptions options = const CacheOptions(),
    int maxSize = 10485760,
  }) async {
    switch (options.source) {
      case Source.server:
        return _fetchFromServer(firebaseUrl, maxSize);
      case Source.cacheServer:
        return await _refreshFile(options, firebaseUrl, maxSize);
    }
  }

  Future<CachedObject> _refreshFile(
    CacheOptions options,
    FirebaseUrl firebaseUrl, [
    int maxSize = 10485760,
  ]) async {
    if (options.checkIfFileUpdatedOnServer) {
      final cachedObject = await _webDbCacheManager.get(firebaseUrl.uniqueId);

      if (cachedObject == null) {
        return _fetchFromServerAndCache(firebaseUrl, maxSize);
      }

      final meta = await firebaseUrl.ref.getMetadata();

      if (meta.updated != null &&
          meta.updated!.millisecondsSinceEpoch > cachedObject.modifiedAt) {
        return _fetchFromServerAndCache(firebaseUrl, maxSize);
      }

      return cachedObject;
    } else {
      final cachedObject = await _webDbCacheManager.get(firebaseUrl.uniqueId);

      if (cachedObject != null) {
        return cachedObject;
      }

      return _fetchFromServerAndCache(firebaseUrl, maxSize);
    }
  }

  Future<void> _saveToCache(CachedObject object) =>
      _webDbCacheManager.put(object, subDir: subDir);

  Future<CachedObject> _fetchFromServer(
    FirebaseUrl firebaseUrl, [
    int maxSize = 10485760,
  ]) async {
    final bytes = await firebaseUrl.ref.getData(maxSize);

    return CachedObject(
      id: firebaseUrl.uniqueId,
      url: firebaseUrl.url.toString(),
      modifiedAt: DateTime.now().millisecondsSinceEpoch,
      rawData: bytes,
    );
  }

  Future<CachedObject> _fetchFromServerAndCache(
    FirebaseUrl firebaseUrl, [
    int maxSize = 10485760,
  ]) async {
    final object = await _fetchFromServer(firebaseUrl, maxSize);

    // Save in bg
    _saveToCache(object);

    return object;
  }

  @override
  Future<bool> isCached(FirebaseUrl firebaseUrl) async {
    return (await _webDbCacheManager.get(firebaseUrl.uniqueId)) != null;
  }

  @override
  Future<String> copyToCache(FirebaseUrl firebaseUrl, String filePath) {
    throw UnsupportedError("Not Supported On Web");
  }
}
