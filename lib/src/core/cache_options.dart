import 'package:firebase_cached_image/src/core/source.dart';

/// Control how file gets fetched and cached
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// if this is set to true then file fetched from cached will get returned
  /// immediately and metadata comparison will happen in background.
  ///
  /// Otherwise metadata comparison is done first then the updated file will
  /// get returned.
  ///
  /// Note: Only applicable if checkForMetadataChange is set to true
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
    this.metadataRefreshInBackground = true,
  });

  @override
  String toString() {
    return 'CacheOptions(source: $source, metadataRefreshInBackground: $metadataRefreshInBackground, checkForMetadataChange: $checkForMetadataChange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheOptions &&
        other.source == source &&
        other.metadataRefreshInBackground == metadataRefreshInBackground &&
        other.checkForMetadataChange == checkForMetadataChange;
  }

  @override
  int get hashCode {
    return source.hashCode ^
        metadataRefreshInBackground.hashCode ^
        checkForMetadataChange.hashCode;
  }
}
