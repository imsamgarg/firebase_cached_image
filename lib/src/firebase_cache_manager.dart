import 'dart:typed_data';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/firebase_storage_manager.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Singleton Cache Manager for Cloud Storage Objects.
class FirebaseCacheManager {
  ///Singleton Instance.
  static late final FirebaseCacheManager instance;
  late final BaseCacheManager _cacheManager;
  static bool _isInitialised = false;
  FirebaseCacheManager._();

  /// Global cacheOptions used for all [FirebaseImageProvider] instances
  late CacheOptions cacheOptions;

  /// Initialise [FirebaseCacheManager]
  static Future<void> initialise() async {
    if (_isInitialised) return;
    instance = FirebaseCacheManager._();
    instance.cacheOptions = CacheOptions(
      shouldCache: !kIsWeb,
      source: kIsWeb ? Source.server : Source.cacheServerByMetadata,
    );
    instance._cacheManager = await CacheManager().init();
    _isInitialised = true;
    return;
  }

  int get _currentTimeInMills => DateTime.now().millisecondsSinceEpoch;

  Future<CachedObject> _getFile({
    FirebaseUrl? url,
    Reference? ref,
    CacheOptions? options,
    int? maxSize,
  }) async {
    assert(url != null || ref != null, "provide url or ref");

    final FirebaseStorageManager _storageManager;
    final Uri uri;
    final _ref = ref ?? url!.ref;
    _storageManager = FirebaseStorageManager.fromRef(_ref);

    if (ref != null) {
      uri = getUriFromRef(ref);
    } else {
      uri = url!.parsedUri;
    }

    final _options = options ?? cacheOptions;
    final _source = _options.source;
    final _shouldCache = _options.shouldCache;

    if (_source == Source.server) {
      final bytes = await _storageManager.get(maxSize);
      return _cacheFile(uri, bytes!, shouldCache: _shouldCache);
    }

    if (_source == Source.cacheServer) {
      final id = getUniqueId(uri.toString());
      final image = await _cacheManager.get(id);

      if (image != null && image.rawData != null) {
        _updateLastAccessedTime(id);
        return image;
      }

      final bytes = await _storageManager.get(maxSize);
      return _cacheFile(uri, bytes!, shouldCache: _shouldCache);
    }

    final id = getUniqueId(uri.toString());
    final image = await _cacheManager.get(id);

    if (image == null || image.rawData == null) {
      final bytes = await _storageManager.get(maxSize);
      return _cacheFile(uri, bytes!, shouldCache: _shouldCache);
    }

    _updateLastAccessedTime(id);

    if (_options.metadataRefreshInBackground) {
      _storageManager.getIfUpdated(image.modifiedAt, maxSize).then(
        (bytes) {
          if (bytes != null && _shouldCache) {
            _updateCachedImage(id, bytes);
          }
        },
      );

      return image;
    }

    final bytes = await _storageManager.getIfUpdated(image.modifiedAt, maxSize);
    if (bytes == null) return image;
    final newImage = image.copyWith(rawData: bytes);

    if (!_shouldCache) return newImage;

    _updateCachedImage(id, bytes);
    return newImage;
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
    /// by default it uses global [cacheOptions]
    CacheOptions? options,

    /// Default: 10MB. The maximum size in bytes to be allocated in the device's memory for the image.
    int? maxSize,
  }) {
    return _getFile(
      url: url,
      maxSize: maxSize,
      options: options,
      ref: ref,
    );
  }

  Future<CachedObject> _cacheFile(
    Uri uri,
    Uint8List bytes, {
    required bool shouldCache,
  }) async {
    final uriString = uri.toString();
    final id = getUniqueId(uriString);

    if (!shouldCache) {
      return createCachedObject(id, url: uriString, bytes: bytes);
    }

    return _cacheManager.put(
      id,
      uri: uriString,
      modifiedAt: _currentTimeInMills,
      bytes: bytes,
    );
  }

  Future<void> _updateLastAccessedTime(String id) {
    return _cacheManager.update(id, lastAccessedAt: _currentTimeInMills);
  }

  Future<void> _updateCachedImage(String id, Uint8List bytes) {
    return _cacheManager.update(
      id,
      modifiedAt: _currentTimeInMills,
      bytes: bytes,
    );
  }

  /// PreCache file from cloud storage
  Future<void> preCache({
    FirebaseUrl? url,
    Reference? ref,
    CacheOptions? options,
    int? maxSize,
  }) async {
    final _cacheOptions = options ??
        CacheOptions(
          metadataRefreshInBackground: false,
          source: Source.cacheServerByMetadata,
        );

    await _getFile(
      url: url,
      maxSize: maxSize,
      options: _cacheOptions,
      ref: ref,
    );
  }

  /// Upload file and then save it to cache for use it later
  Future<CachedObject> uploadAndCache({
    required Reference ref,
    required Uint8List bytes,
    SettableMetadata? metadata,
    UploadTask Function(UploadTask task)? uploadTaskCallback,
  }) async {
    final _manager = FirebaseStorageManager.fromRef(ref);
    UploadTask task = _manager.putData(bytes, metadata);
    task = uploadTaskCallback?.call(task) ?? task;
    await task;

    final uri = getUriFromRef(ref);
    final url = uri.toString();
    final id = getUniqueId(url);

    return _cacheManager.put(
      id,
      uri: url,
      modifiedAt: _currentTimeInMills,
      bytes: bytes,
    );
  }

  /// Delete all the cached files
  Future<void> clearCache() => _cacheManager.clear();

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
    return _cacheManager.delete(id);
  }
}
