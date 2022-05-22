part of firebase_cached_image;

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
