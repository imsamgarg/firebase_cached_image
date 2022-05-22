import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_settings.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';

const kImageCacheBox = "images_box";

abstract class BaseCacheManager {
  late final Box<CachedImage> box;

  Future<BaseCacheManager> init();

  Future dispose();

  Future<Uint8List?> get(
    Uri uri, {
    required Reference ref,
    required bool shouldCache,
    required CacheRefreshStrategy refreshStrategy,
  }) async {
    final _key = uri.toString();
    final image = box.get(_key);
    if (image == null) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    final localPath = image.uri;
    final cachedData = getFromCache(localPath);
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
    final imageModel = box.get(uri.toString());
    if (imageModel == null) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    final metadata = await ref.getMetadata();
    final modifiedAt = metadata.updated?.millisecondsSinceEpoch ?? -1;
    if (modifiedAt > imageModel.modifiedAt) {
      return getFromServer(uri, ref: ref, shouldCache: shouldCache);
    }

    final cachedData = getFromCache(imageModel.localPath);
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

  Uint8List? getFromCache(String localPath);

  Future<void> clearCache() async {
    await box.clear();
    await box.flush();
  }

  Future<void> deleteFromCache(Uri uri) async {
    await box.delete("$uri");
    await box.flush();
  }
}

//Stub Class
class CacheManager extends BaseCacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
