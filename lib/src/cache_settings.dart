class CacheSettings {
  final Source source;
  final bool shouldCache;
  final bool metadataRefreshInBackground;
  CacheSettings({
    this.source = Source.cacheServer,
    this.shouldCache = true,
    this.metadataRefreshInBackground = true,
  });
}

enum Source { server, cacheServer, cacheServerByMetadata }
