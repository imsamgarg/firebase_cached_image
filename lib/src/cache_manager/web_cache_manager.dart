import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';

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
  Future<CachedObject?> get(String id) async => null;

  @override
  Future<CachedObject> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
  }) async {
    return CachedObject(
      id: id,
      fullLocalPath: "",
      uri: uri,
      modifiedAt: modifiedAt,
    );
  }

  @override
  Future<void> update(
    String id, {
    int? modifiedAt,
    Uint8List? bytes,
    int? lastAccessedAt,
  }) async {}
}
