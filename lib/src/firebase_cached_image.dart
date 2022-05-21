import 'package:firebase_cached_image/src/cache_manager/cache_manager.dart'
    if (dart.library.html) 'package:firebase_cached_image/src/cache_manager/web_cache_manager.dart'
    if (dart.library.io) 'package:firebase_cached_image/src/cache_manager/mobile_cache_manager.dart';
import 'package:firebase_cached_image/src/cache_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'image_provider.dart';

class FirebaseCachedImage {
  static late final FirebaseCachedImage instance;
  late final BaseCacheManager _cacheManager;

  CacheSettings cacheSettings = CacheSettings();

  static bool _isInitialised = false;

  FirebaseCachedImage._();

  static Future<void> initialise() async {
    if (_isInitialised) return;

    instance = FirebaseCachedImage._();
    instance._cacheManager = await CacheManager().init();
    _isInitialised = true;
    return;
  }
}
