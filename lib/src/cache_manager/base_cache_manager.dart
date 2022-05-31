import 'dart:typed_data';

import 'package:firebase_cached_image/src/cached_object_model.dart';

export 'package:firebase_cached_image/src/cache_manager/stub_cache_manager.dart'
    if (dart.library.html) 'package:firebase_cached_image/src/cache_manager/web_cache_manager.dart'
    if (dart.library.io) 'package:firebase_cached_image/src/cache_manager/mobile_cache_manager.dart';

abstract class BaseCacheManager {
  Future<CachedObjectModel?> get(String id);
  Future<void> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
  });
  Future<void> update(
    String id, {
    int? modifiedAt,
    int? lastAccessedAt,
    Uint8List? bytes,
  });
  Future<void> delete(String id);
  Future<void> clear();
  Future<BaseCacheManager> init();
}
