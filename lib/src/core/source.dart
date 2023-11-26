/// The source from which file gets fetched
enum Source {
  /// Directly fetch latest file from server not from cache
  ///
  /// Note: file will not be saved in the cache.
  server,

  /// First try to fetch file from cache then try to fetch from server if
  /// file does not exist in cache.
  ///
  /// Default..
  cacheServer,
}
