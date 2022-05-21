class CacheSettings {
  final bool shouldCache;
  final CacheRefreshStrategy cacheRefreshStrategy;

  CacheSettings({
    this.shouldCache = true,
    this.cacheRefreshStrategy = CacheRefreshStrategy.byMetadata,
  });
}

enum CacheRefreshStrategy { byMetadata, never }

enum CacheOptions { server, cacheAndServer, cacheAndServerByMetadata }
