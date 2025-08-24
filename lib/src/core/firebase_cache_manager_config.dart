// ignore_for_file: avoid_classes_with_only_static_members

/// Global Configuration class for Firebase Cache Manager
class FirebaseCacheManagerConfig {
  /// Enables or disables web cache support for the Firebase Cache Manager. By enabling this, the package will utilize IndexedDB for caching images when running in a web browser.
  ///
  /// WARN: Expermintal feature.
  static bool webSupport = false;
}
