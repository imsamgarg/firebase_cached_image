import 'package:firebase_cached_image/src/core/source.dart';

/// Control how file gets fetched and cached
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// if this is set to true then a server call will be made to check whether
  /// the file has been updated or not. If its updated then we will cache the
  /// updated file in background.
  ///
  /// Default false.
  final bool checkForMetadataChange;

  /// Control how file gets fetched and cached
  const CacheOptions({
    this.checkForMetadataChange = false,
    this.source = Source.cacheServer,
  });

  @override
  String toString() =>
      'CacheOptions(source: $source, checkForMetadataChange: $checkForMetadataChange)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheOptions &&
        other.source == source &&
        other.checkForMetadataChange == checkForMetadataChange;
  }

  @override
  int get hashCode => source.hashCode ^ checkForMetadataChange.hashCode;
}
