import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'firebase_image_provider.dart';

const _kDefaultMaxSize = 10485760;
const _defaultCacheOptions = CacheOptions(
  shouldCache: !kIsWeb,
  source: kIsWeb ? Source.server : Source.cacheServerByMetadata,
);

/// Singleton Cache Manager for Cloud Storage Objects.
class FirebaseCacheManager {
  static int get _nowTime => DateTime.now().millisecondsSinceEpoch;

  static Future<T> _initCacheManager<T>(
    Future<T> Function(BaseCacheManager manager) op,
  ) async {
    final cacheManager = await CacheManager().init();
    try {
      final value = await op(cacheManager);

      await cacheManager.dispose();
      return value;
    } on Exception {
      await cacheManager.dispose();
      rethrow;
    }
  }

  Future<CachedObject> _getFile({
    required BaseCacheManager manager,
    required Source source,
    required Reference ref,
    required int maxSize,
    required String id,
  }) async {
    late final Uint8List? bytes;

    if (source == Source.server) bytes = await ref.getData(maxSize);

    if (source == Source.cacheServer) {
      final image = await manager.get(id);

      if (image != null && image.rawData != null) {
        manager.update(id, lastAccessedAt: _nowTime);
        return image;
      }

      bytes = await ref.getData(maxSize);
    }

    if (source == Source.cacheServerByMetadata) {
      final image = await manager.get(id);

      if (image?.rawData == null) {
        bytes = await ref.getData(maxSize);
      }

      final metadata = await ref.getMetadata();
      final updatedAt = metadata.updated?.millisecondsSinceEpoch;
      if (updatedAt == null || updatedAt <= image!.modifiedAt) return image!;

      final newBytes = await ref.getData(maxSize);
      return CachedObject(id: id, uri: "", modifiedAt: 1, rawData: newBytes);
    }

    return CachedObject(
      id: id,
      uri: id,
      modifiedAt: _nowTime,
      rawData: bytes,
    );
  }

  Future<void> _cacheFile({
    required BaseCacheManager manager,
    required CachedObject file,
  }) {
    return manager.update(
      file.id,
      bytes: file.rawData,
      lastAccessedAt: _nowTime,
      modifiedAt: _nowTime,
    );
  }

  /// Fetch, cache and return [Uint8List] bytes for Cloud Storage File.
  ///
  /// You need to specify [firebaseUrl] or [ref]. [firebaseUrl] must start with 'gs://'.
  /// If you passed both then [ref] will be used. Both [firebaseUrl] and [ref] can not be null.
  ///
  /// you can control how file gets fetched and cached by passing [options].
  Future<CachedObject> getSingleFile({
    /// The FirebaseUrl of the Cloud Storage image
    ///
    /// example:
    /// ```
    /// FirebaseUrl("gs://bucket_f233/logo.jpg")
    /// ```
    ///
    /// you can specify [FirebaseApp] if you are multiple firebase projects in app
    /// ex:
    ///
    /// ```
    /// FirebaseUrl("gs://bucket_f233/logo.jpg", app: Firebase.app("app_name"));
    ///
    /// ```
    FirebaseUrl? url,

    /// Cloud Storage reference to the object in the storage.
    Reference? ref,

    /// Control how image gets fetched and cached
    ///
    /// by default it uses global [_defaultCacheOptions]
    CacheOptions? options,

    /// Default: 10MB. The maximum size in bytes to be allocated in the device's memory for the image.
    int? maxSize,
  }) {
    assert(url != null || ref != null, "provide url or ref");

    final Uri uri;
    final _ref = ref ?? url!.ref;

    if (ref != null) {
      uri = getUriFromRef(ref);
    } else {
      uri = url!.parsedUri;
    }

    final urlString = uri.toString();
    final id = getUniqueId(urlString);
    final _options = options ?? _defaultCacheOptions;

    return _initCacheManager((manager) async {
      final cachedObject = await _getFile(
        maxSize: maxSize ?? _kDefaultMaxSize,
        id: id,
        manager: manager,
        source: _options.source,
        ref: _ref,
      );
      final bytes = cachedObject.rawData;
      final file = createCachedObject(id, url: urlString, bytes: bytes);

      if (cachedObject.fullLocalPath != null) {
        // await manager.update(id, lastAccessedAt: _nowTime);
        return file;
      }

      if (!_options.shouldCache) {
        // await manager.update(id, lastAccessedAt: _nowTime);

        return file;
      }

      await _cacheFile(manager: manager, file: file);
      return file;
    });
  }

  /// PreCache file from cloud storage
  Future<void> preCache({
    FirebaseUrl? url,
    Reference? ref,
    CacheOptions? options,
    int? maxSize,
  }) async {
    await getSingleFile(
      maxSize: maxSize,
      options: options,
      ref: ref,
      url: url,
    );
  }

  /// Upload file and then save it to cache for use it later
  Future<CachedObject> uploadAndCache({
    required Reference ref,
    required Uint8List bytes,
    SettableMetadata? metadata,
    UploadTask Function(UploadTask task)? uploadTaskCallback,
  }) async {
    UploadTask task = ref.putData(bytes, metadata);
    task = uploadTaskCallback?.call(task) ?? task;
    await task;

    final uri = getUriFromRef(ref);
    final url = uri.toString();
    final id = getUniqueId(url);

    return _initCacheManager((manager) {
      return manager.put(
        id,
        uri: url,
        modifiedAt: _nowTime,
        bytes: bytes,
      );
    });
  }

  /// Delete all the cached files
  Future<void> clearCache() => _initCacheManager((manager) => manager.clear());

  /// Delete specific file from cache
  Future<void> delete({
    FirebaseUrl? url,
    Reference? ref,
  }) {
    assert(url != null || ref != null, "provide url or ref");
    late final Uri uri;

    if (ref != null) {
      uri = getUriFromRef(ref);
    } else {
      uri = url!.parsedUri;
    }

    final id = getUniqueId(uri.toString());
    return _initCacheManager((manager) => manager.delete(id));
  }
}
