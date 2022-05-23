import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';

class FirebaseCachedImage {
  static late final FirebaseCachedImage instance;
  late final BaseCacheManager _cacheManager;

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
