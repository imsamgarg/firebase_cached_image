import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_settings.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:firebase_storage/firebase_storage.dart';

export 'package:firebase_cached_image/src/cache_manager/mobile_cache_manager.dart'
    if (dart.library.html) 'package:firebase_cached_image/src/cache_manager/web_cache_manager.dart';

const kImageCacheBox = "images_box";

abstract class BaseCacheManager {
  Future<BaseCacheManager> init();

  Future dispose();

  Future<CachedImage?> getCachedImageModel(String key);
  Future<void> saveCachedImageModel(String key, CachedImage image);

  Future<Uint8List?> get(
    Uri uri, {
    required Reference ref,
    required bool shouldCache,
    required CacheRefreshStrategy refreshStrategy,
  }) async {
    final _key = uri.toString();
    final image = await getCachedImageModel(_key);
    if (image == null) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    final localPath = image.uri;
    final cachedData = await getFromCache(localPath);
    if (cachedData == null) {
      await getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    if (refreshStrategy == CacheRefreshStrategy.byMetadata && shouldCache) {
      //refresh cache in background
      getFromServerByMetadata(uri, ref: ref, shouldCache: shouldCache);
    }

    return cachedData;
  }

  Future<Uint8List?> getFromServerByMetadata(
    Uri uri, {
    required Reference ref,
    required bool shouldCache,
  }) async {
    final imageModel = await getCachedImageModel(uri.toString());
    if (imageModel == null) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    final metadata = await ref.getMetadata();
    final modifiedAt = metadata.updated?.millisecondsSinceEpoch ?? -1;
    if (modifiedAt > imageModel.modifiedAt) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    final cachedData = await getFromCache(imageModel.localPath);
    if (cachedData == null) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    return cachedData;
  }

  Future<Uint8List?> getFromServer(
    Uri uri, {
    required Reference ref,
    required bool shouldCache,
  }) async {
    final data = await ref.getData();

    if (shouldCache) cacheImage(data, ref: ref, uri: uri);

    return data;
  }

  Future<CachedImage> cacheImage(
    Uint8List? data, {
    required Uri uri,
    required Reference ref,
  });

  Future<Uint8List?> getFromCache(String localPath);

  Future<void> clearCache();

  Future<void> deleteFromCache(Uri uri);
}
