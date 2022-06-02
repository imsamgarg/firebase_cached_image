import 'package:firebase_cached_image/src/core/source.dart';

/// Control how file gets fetched and cached
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// Whether file should be cached or not
  final bool shouldCache;

  /// if this is set to true then file fetched from cached will get returned
  /// immediately and metadata comparison will happen in background.
  ///
  /// Otherwise metadata comparison is done first then the updated file will
  /// get returned.
  ///
  /// Note: Only applicable if source is set to source.cacheServerByMetadata
  final bool metadataRefreshInBackground;

  /// Control how file gets fetched and cached
  CacheOptions({
    this.source = Source.cacheServer,
    this.shouldCache = true,
    this.metadataRefreshInBackground = true,
  });
}
