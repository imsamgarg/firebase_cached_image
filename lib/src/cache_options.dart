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
