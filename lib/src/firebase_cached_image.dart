import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cache_settings.dart';
import 'package:firebase_cached_image/src/firebase_storage_manager.dart';
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseCachedImage {
  static late final FirebaseCachedImage instance;
  late final BaseCacheManager _cacheManager;

  static bool _isInitialised = false;

  CacheSettings cacheSettings = CacheSettings();
  FirebaseCachedImage._();

  static Future<void> initialise() async {
    if (_isInitialised) return;
    instance = FirebaseCachedImage._();
    instance._cacheManager = await CacheManager().init();
    _isInitialised = true;
    return;
  }

  Future<Uint8List?> get(
    String firebaseUri, {
    Reference? ref,
    CacheSettings? settings,
    int? maxSize,
  }) async {
    final FirebaseStorageManager _storageManager;
    final Uri uri;

    if (ref != null) {
      uri = getUriFromRef(ref);
      _storageManager = FirebaseStorageManager.fromRef(ref);
    } else {
      uri = Uri.parse(firebaseUri);
      _storageManager = FirebaseStorageManager.fromUri(uri);
    }

    final _settings = settings ?? cacheSettings;
    final _source = _settings.source;
    final _shouldCache = _settings.shouldCache;

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

    if (_settings.metadataRefreshInBackground) {
      _storageManager.getIfUpdated(image.modifiedAt, maxSize).then(
        (bytes) {
          if (bytes != null && !_shouldCache) _cacheImage(bytes, uri);
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
