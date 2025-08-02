import 'package:firebase_cached_image/src/core/source.dart';

/// Control how file gets fetched and cached
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// If this is set to true then a server call will be made to check whether the
  /// file has been updated on the server or not. If its updated then we will download the latest file and the save it in the cache.
  ///
  /// Default false.
  final bool checkIfFileUpdatedOnServer;

  /// For how much time the file is valid in the cache.
  ///
  /// Note: If this is specified then the [checkIfFileUpdatedOnServer] will be ignored.
  final Duration? maxAge;

  /// Control how file gets fetched and cached
  const CacheOptions({
    @Deprecated('Use [checkIfFileUpdatedOnServer] instead')
    bool checkForMetadataChange = false,
    bool checkIfFileUpdatedOnServer = false,
    this.source = Source.cacheServer,
    this.maxAge,
  })
  // For backward compatibility
  : checkIfFileUpdatedOnServer =
            checkForMetadataChange || checkIfFileUpdatedOnServer;

  @override
  String toString() =>
      'CacheOptions(source: $source, checkIfFileUpdatedOnServer: $checkIfFileUpdatedOnServer, maxAge: $maxAge)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheOptions &&
        other.source == source &&
        other.checkIfFileUpdatedOnServer == checkIfFileUpdatedOnServer &&
        other.maxAge == maxAge;
  }

  @override
  int get hashCode => Object.hash(source, checkIfFileUpdatedOnServer, maxAge);
}
