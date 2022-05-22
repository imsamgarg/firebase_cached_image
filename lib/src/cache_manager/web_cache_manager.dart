import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/cache_manager.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';

class CacheManager extends BaseCacheManager {
  @override
  Future<BaseCacheManager> init() async {
    Hive.registerAdapter(CachedImageAdapter());

    box = await Hive.openBox<CachedImage>(kImageCacheBox);
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

    box.put(_imageModel.uri, _imageModel);
    await box.flush();

    return _imageModel;
  }

  @override
  Uint8List? getFromCache(String localPath) => box.get(localPath)?.rawData;

  @override
  Future dispose() => Hive.close();
}
