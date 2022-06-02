import 'package:firebase_cached_image/src/core/cache_options.dart';

/// The source from which file gets fetched
enum Source {
  /// Directly fetch file from server not from cache
  ///
  /// Note: file will still get cached.
  server,

  /// First try to fetch file from cache then try to fetch from server if
  /// file does not exist in cache.
  cacheServer,

  /// First try to fetch file from cache then if file does not exist then file
  /// will get fetched from server
  ///
  /// but if file does exist then it will compare the metadata of the file to the
  /// file in server if server has updated file then it will fetch file from server
  /// otherwise return file from cache.
  ///
  /// you can control whether metadata comparison happen in background or not by using
  /// [CacheOptions.metadataRefreshInBackground] flag
  cacheServerByMetadata,
}
