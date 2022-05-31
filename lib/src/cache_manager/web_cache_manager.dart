import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_object_model.dart';

class CacheManager extends BaseCacheManager {
  @override
  Future<CacheManager> init() async {
    return this;
  }

  @override
  Future<void> clear() async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<CachedObjectModel?> get(String id) async => null;

  @override
  Future<void> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
  }) async {}

  @override
  Future<void> update(
    String id, {
    int? modifiedAt,
    Uint8List? bytes,
    int? lastAccessedAt,
  }) async {}
}
