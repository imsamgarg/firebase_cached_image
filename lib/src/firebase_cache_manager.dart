import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cache_options.dart';
import 'package:firebase_cached_image/src/cached_object.dart';
import 'package:firebase_cached_image/src/firebase_image_provider.dart';
import 'package:firebase_cached_image/src/firebase_storage_manager.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Singleton Cache Manager for Cloud Storage Objects.
///
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

  /// Fetch, cache and return [Uint8List] bytes for Cloud Storage Image.
  ///
  /// You need to specify [firebaseUrl] or [ref]. [firebaseUrl] must start with 'gs://'.
  /// If you passed both then [ref] will be used. Both [firebaseUrl] and [ref] can not be null.
  ///
  /// you can control how file gets fetched and cached by passing [options].
  Future<Uint8List?> getSingleImage({
    /// The Url of the Cloud Storage Object
    ///
    /// example: gs://bucket_f233/dp.jpg
    String? firebaseUrl,

    /// Cloud Storage reference to the object in the storage.
    Reference? ref,

    /// Default: the default Firebase app. Specifies a custom Firebase app to make the request to the bucket from
    FirebaseApp? firebaseApp,

    /// Control how image gets fetched and cached
    ///
    /// by default it uses global [cacheOptions]
    CacheOptions? options,

    /// Default: 10MB. The maximum size in bytes to be allocated in the device's memory for the image.
    int? maxSize,
  }) async {
    assert(firebaseUrl != null || ref != null, "provide firebaseUrl or ref");

    final FirebaseStorageManager _storageManager;
    final Uri uri;

    if (ref != null) {
      uri = getUriFromRef(ref);
      _storageManager = FirebaseStorageManager.fromRef(ref);
    } else {
      uri = Uri.parse(firebaseUrl!);
      _storageManager = FirebaseStorageManager.fromUri(uri, app: firebaseApp);
    }

    final _options = options ?? cacheOptions;
    final _source = _options.source;
    final _shouldCache = _options.shouldCache;

    if (_source == Source.server) {
      return _getFromServerAndCache(
        manager: _storageManager,
        shouldCache: _shouldCache,
        uri: uri,
        maxSize: maxSize,
      );
    }

    if (_source == Source.cacheServer) {
      final id = getUniqueId(uri.toString());
      final image = await _cacheManager.get(id);

      if (image != null && image.rawData != null) {
        _updateLastAccessedTime(id);
        return image.rawData;
      }

      return _getFromServerAndCache(
        manager: _storageManager,
        shouldCache: _shouldCache,
        uri: uri,
        maxSize: maxSize,
      );
    }

    final id = getUniqueId(uri.toString());
    final image = await _cacheManager.get(id);
    if (image == null || image.rawData == null) {
      return _getFromServerAndCache(
        manager: _storageManager,
        shouldCache: _shouldCache,
        uri: uri,
        maxSize: maxSize,
      );
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

      return image.rawData;
    }

    final bytes = await _storageManager.getIfUpdated(image.modifiedAt, maxSize);

    if (bytes == null) return image.rawData;
    if (!_shouldCache) return bytes;

    _updateCachedImage(id, bytes);
    return bytes;
  }

  Future<Uint8List?> _getFromServerAndCache({
    required Uri uri,
    required bool shouldCache,
    required FirebaseStorageManager manager,
    int? maxSize,
  }) async {
    final bytes = await manager.get(maxSize);
    if (!shouldCache) return bytes;

    _cacheImage(bytes!, uri);
    return bytes;
  }

  Future<void> _cacheImage(
    Uint8List bytes,
    Uri uri,
  ) {
    final uriString = uri.toString();
    final id = getUniqueId(uriString);

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
    String? firebaseUrl,
    Reference? ref,
    FirebaseApp? firebaseApp,
    CacheOptions? options,
    int? maxSize,
  }) async {
    final _cacheOptions = options ??
        CacheOptions(
          metadataRefreshInBackground: false,
          source: Source.cacheServerByMetadata,
        );

    await getSingleImage(
      firebaseApp: firebaseApp,
      firebaseUrl: firebaseUrl,
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
    final currentTimeInMills = DateTime.now().millisecondsSinceEpoch;

    return _cacheManager.put(
      id,
      uri: url,
      modifiedAt: currentTimeInMills,
      bytes: bytes,
    );
  }

  /// Delete all the cached files
  Future<void> clearCache() => _cacheManager.clear();

  /// Delete specific file from cache
  Future<void> delete({
    String? firebaseUrl,
    Reference? ref,
    FirebaseApp? firebaseApp,
  }) {
    assert(firebaseUrl != null || ref != null, "provide firebaseUrl or ref");
    late final Uri uri;

    if (ref != null) {
      uri = getUriFromRef(ref);
    } else {
      uri = Uri.parse(firebaseUrl!);
    }

    final id = getUniqueId(uri.toString());
    return _cacheManager.delete(id);
  }
}
