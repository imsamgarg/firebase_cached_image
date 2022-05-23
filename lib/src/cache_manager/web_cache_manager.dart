import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';

class CacheManager extends BaseCacheManager {
  late final LazyBox<CachedImage> _box;
  @override
  Future<BaseCacheManager> init() async {
    Hive.registerAdapter(CachedImageAdapter());

    _box = await Hive.openLazyBox<CachedImage>(kImageCacheBox);
    return this;
  }

  @override
  Future<CachedImage> cacheImage(
    Uint8List? data, {
    required Uri uri,
    required Reference ref,
  }) async {
    final _time = DateTime.now();

    final _imageModel = CachedImage(
      uri: uri.toString(),
      modifiedAt: _time.millisecondsSinceEpoch,
      cachedAt: _time.millisecondsSinceEpoch,
      localPath: uri.toString(),
      //image data will be stored in database on web
      rawData: data,
    );

    _box.put(_imageModel.uri, _imageModel);
    await _box.flush();

    return _imageModel;
  }

  @override
  Future<Uint8List?> getFromCache(String localPath) async {
    final image = await _box.get(localPath);
    return image?.rawData;
  }

  @override
  Future dispose() => Hive.close();

  @override
  Future<void> clearCache() async {
    await _box.clear();
    return _box.flush();
  }

  @override
  Future<void> deleteFromCache(Uri uri) async {
    await _box.delete(uri.toString());
    return _box.flush();
  }

  @override
  Future<CachedImage?> getCachedImageModel(String key) {
    return _box.get(key);
  }

  @override
  Future<void> saveCachedImageModel(String key, CachedImage image) {
    return _box.put(key, image);
  }
}
