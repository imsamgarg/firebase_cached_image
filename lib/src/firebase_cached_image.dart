import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cache_options.dart';
import 'package:firebase_cached_image/src/firebase_storage_manager.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_cached_image/src/image_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Singleton Cache Manager for Cloud Storage Objects.
class FirebaseCachedImage {
  ///Singleton Instance.
  static late final FirebaseCachedImage instance;
  late final BaseCacheManager _cacheManager;
  static bool _isInitialised = false;
  FirebaseCachedImage._();

  /// Global cacheOptions used for all [FirebaseImageProvider] instances
  CacheOptions cacheOptions = CacheOptions();

  /// Initialise [FirebaseCachedImage]
  static Future<void> initialise() async {
    if (_isInitialised) return;
    instance._cacheManager = await CacheManager().init();
    instance = FirebaseCachedImage._();
    _isInitialised = true;
    return;
  }

  /// Fetch, cache and return [Uint8List] bytes for Cloud Storage Objects.
  ///
  /// You need to specify [firebaseUrl] or [ref]. [firebaseUrl] must start with 'gs://'.
  /// If you passed both then [ref] will be used. Both [firebaseUrl] and [ref] can not be null.
  ///
  /// you can control how file gets fetched and cached by passing [options].
  Future<Uint8List?> get({
    /// The Url of the Cloud Storage Object
    ///
    /// example: gs://bucket_f233/document.pdf
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
      if (image != null) return image.rawData;

      return _getFromServerAndCache(
        manager: _storageManager,
        shouldCache: _shouldCache,
        uri: uri,
        maxSize: maxSize,
      );
    }

    final id = getUniqueId(uri.toString());
    final image = await _cacheManager.get(id);
    if (image == null) {
      return _getFromServerAndCache(
        manager: _storageManager,
        shouldCache: _shouldCache,
        uri: uri,
        maxSize: maxSize,
      );
    }

    if (_options.metadataRefreshInBackground) {
      _storageManager.getIfUpdated(image.modifiedAt, maxSize).then(
        (bytes) {
          if (bytes != null && _shouldCache) _cacheImage(bytes, uri);
        },
      );

      return image.rawData;
    }

    final bytes = await _storageManager.getIfUpdated(image.modifiedAt, maxSize);

    if (bytes == null) return image.rawData;
    if (!_shouldCache) return bytes;

    _cacheImage(bytes, uri);
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

  Future<void> _cacheImage(Uint8List bytes, Uri uri) {
    final uriString = uri.toString();
    final id = getUniqueId(uriString);
    final currentTimeInMills = DateTime.now().millisecondsSinceEpoch;

    return _cacheManager.put(
      id,
      uri: uriString,
      modifiedAt: currentTimeInMills,
      bytes: bytes,
    );
  }
}
