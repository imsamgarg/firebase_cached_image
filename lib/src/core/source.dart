/// The source from which file gets fetched
enum Source {
  /// Directly fetch file from server not from cache
  ///
  /// Note: file will still get cached.
  server,

  /// First try to fetch file from cache then try to fetch from server if
  /// file does not exist in cache.
  ///
  /// Default..
  cacheServer,
}
