import 'dart:io';

import 'package:firebase_cached_image/src/core/cache_options.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/core/firebase_url.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseCacheManager extends BaseFirebaseCacheManager{
  FirebaseCacheManager({super.subDir});

  @override
  Future<void> clearCache({Duration? modifiedBefore}) => Future.value();

  @override
  Future<void> delete(FirebaseUrl firebaseUrl) => Future.value();

  @override
  Future<String> getSingleFile(
    FirebaseUrl firebaseUrl, {
    Reference? ref,
    CacheOptions options = const CacheOptions(),
  }) {
    throw UnsupportedError("Not Supported On Web");
  }

  @override
  Future<void> preCacheFile(FirebaseUrl firebaseUrl) => Future.value();

  @override
  Future<void> refreshCachedFile(FirebaseUrl firebaseUrl) => Future.value();

  @override
  Future<void> copyFileToCache(File fileToCache, FirebaseUrl firebaseUrl) => Future.value();

  @override
  Future<CachedObject> getSingleObject(
    FirebaseUrl firebaseUrl, {
    //Cache options are ignored in web
    CacheOptions options = const CacheOptions(),
    int maxSize = 10485760,
  }) async {
    final bytes = await firebaseUrl.ref.getData(maxSize);

    return CachedObject(
      id: firebaseUrl.uniqueId,
      url: firebaseUrl.url.toString(),
      modifiedAt: DateTime.now().millisecondsSinceEpoch,
      rawData: bytes,
    );
  }

  @override
  Future<bool> isCached(FirebaseUrl firebaseUrl) {
    //Always return false on web.
    return Future.value(false);
  }
}
