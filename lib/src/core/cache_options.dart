import 'package:firebase_cached_image/src/core/source.dart';

/// Control how file gets fetched and cached
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// if this is set to true then a server call will be made to check whether the
  /// file has been updated on the server or not. If its updated then we will download the latest file and the save it in the cache.
  ///
  /// Default false.
  final bool checkIfFileUpdatedOnServer;

  /// Control how file gets fetched and cached
  const CacheOptions({
    @Deprecated('Use [checkIfFileUpdatedOnServer] instead')
    bool checkForMetadataChange = false,
    bool checkIfFileUpdatedOnServer = false,
    this.source = Source.cacheServer,
  })
  // For backward compatibility
  : checkIfFileUpdatedOnServer =
            checkForMetadataChange || checkIfFileUpdatedOnServer;

  @override
  String toString() =>
      'CacheOptions(source: $source, checkIfFileUpdatedOnServer: $checkIfFileUpdatedOnServer)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheOptions &&
        other.source == source &&
        other.checkIfFileUpdatedOnServer == checkIfFileUpdatedOnServer;
  }

  @override
  int get hashCode => source.hashCode ^ checkIfFileUpdatedOnServer.hashCode;
}
