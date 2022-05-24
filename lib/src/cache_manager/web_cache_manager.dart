import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:hive/hive.dart';

const _kImageCacheBox = "images_box";

class CacheManager extends BaseCacheManager {
  late final LazyBox<CachedImage> _box;

  @override
  Future<BaseCacheManager> init() async {
    Hive.registerAdapter(CachedImageAdapter());

    _box = await Hive.openLazyBox<CachedImage>(_kImageCacheBox);
    return this;
  }

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.flush();
  }

  @override
  Future<CachedImage?> delete(String id) async {
    final image = await _box.get(id);
    if (image == null) return null;

    await _box.delete(id);
    await _box.flush();
    return image;
  }

  @override
  Future<CachedImage?> get(String id) => _box.get(id);

  @override
  Future<void> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
    int? cachedAt,
  }) async {
    final _imageForDb = CachedImage(
      id: id,
      fullLocalPath: id,
      uri: uri,
      modifiedAt: modifiedAt,
      cachedAt: cachedAt,
    );

    await _box.put(id, _imageForDb);
    await _box.flush();
  }
}
