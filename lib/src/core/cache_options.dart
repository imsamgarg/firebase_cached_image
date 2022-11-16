import 'package:firebase_cached_image/src/core/source.dart';

/// Control how file gets fetched and cached
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// Whether file should be cached or not
  @Deprecated("Not used anymore")
  final bool shouldCache;

  /// if this is set to true then file fetched from cached will get returned
  /// immediately and metadata comparison will happen in background.
  ///
  /// Otherwise metadata comparison is done first then the updated file will
  /// get returned.
  ///
  /// Note: Only applicable if source is set to source.cacheServerByMetadata
  final bool metadataRefreshInBackground;

  /// if this is set to true then a server call will be made to check whether
  /// the file has been updated or not. If its updated then we will cache the
  /// updated file in background.
  ///
  /// Default true.
  final bool checkForMetadataChange;

  /// Control how file gets fetched and cached
  const CacheOptions({
    this.checkForMetadataChange = true,
    this.source = Source.cacheServer,
    @Deprecated("Not used anymore") this.shouldCache = true,
    this.metadataRefreshInBackground = true,
  });
}
