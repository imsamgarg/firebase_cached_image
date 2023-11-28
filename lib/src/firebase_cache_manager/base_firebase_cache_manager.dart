import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/core/cached_object.dart';

const kDefaultImageCacheDir = "flutter_cached_image";

/// [FirebaseCacheManager]
abstract class BaseFirebaseCacheManager {
  /// Use this to save files in desired directory in system's temporary directory
  final String subDir;

  BaseFirebaseCacheManager({this.subDir = kDefaultImageCacheDir});

  /// Fetch, cache and returns the localFilePath for Cloud Storage File.
  ///
  /// You need to specify [firebaseUrl]
  ///
  /// you can control how file gets fetched and cached by passing [options].
  ///
  /// throws [UnsupportedError] in web;
  Future<String> getSingleFile(
    /// The FirebaseUrl of the Cloud Storage image
    ///
    /// example:
    /// ```
    /// FirebaseUrl("gs://bucket_f233/logo.jpg")
    /// ```
    FirebaseUrl firebaseUrl, {
    /// Control how image gets fetched and cached
    CacheOptions options = const CacheOptions(),
  });

  /// Used internally by [FirebaseImageProvider] as of now.
  ///
  /// Returns [CachedObject].
  /// File buffer will be stored in [CachedObject.rawData] property;
  ///
  /// Should not be used as it loads the entire file in memory and then returns
  /// the buffer to the caller. Use [getSingleFile] for better performance.
  Future<CachedObject> getSingleObject(
    /// The FirebaseUrl of the Cloud Storage image
    ///
    /// example:
    /// ```
    /// FirebaseUrl("gs://bucket_f233/logo.jpg")
    /// ```
    FirebaseUrl firebaseUrl, {
    /// Control how image gets fetched and cached
    CacheOptions options = const CacheOptions(),

    /// If the [maxSize] (in bytes) is exceeded, the operation will be canceled. By
    /// default the [maxSize] is 10mb (10485760 bytes).
    int maxSize,
  });

  /// Refresh already cached file..
  ///
  /// Checks if the file has been updated in server, then download the file if
  /// it has been updated and saves it to cache.
  Future<void> refreshCachedFile(FirebaseUrl firebaseUrl);

  /// PreCache file from cloud storage
  ///
  /// Note: If the file already exists in cache then it won't do anything, if you
  /// want to update the cache file if its updated in serve then use [refreshCachedFile]..
  Future<void> preCacheFile(FirebaseUrl firebaseUrl);

  /// Delete all the cached files
  Future<void> clearCache({
    /// Only delete files updated before [modifiedBefore]
    Duration? modifiedBefore,
  });

  /// Delete specific file from cache
  Future<void> delete(FirebaseUrl firebaseUrl);

  /// Check whether the file is cached or not.
  ///
  /// On web it always return false.
  Future<bool> isCached(FirebaseUrl firebaseUrl);
}
