import 'dart:typed_data';

import 'package:hive/hive.dart';

class CachedImage {
  final String localPath;
  final String uri;
  final int? cachedAt;
  final int modifiedAt;
  final Uint8List? rawData;
  CachedImage({
    required this.localPath,
    required this.uri,
    this.cachedAt,
    required this.modifiedAt,
    this.rawData,
  });

  CachedImage copyWith({
    String? localPath,
    String? uri,
    int? cachedAt,
    int? modifiedAt,
    Uint8List? rawData,
  }) {
    return CachedImage(
      localPath: localPath ?? this.localPath,
      uri: uri ?? this.uri,
      cachedAt: cachedAt ?? this.cachedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'localPath': localPath,
      'uri': uri,
      'cachedAt': cachedAt,
      'modifiedAt': modifiedAt,
      'rawData': rawData,
    };
  }

  factory CachedImage.fromMap(Map<String, dynamic> map) {
    return CachedImage(
      localPath: map['localPath'] as String,
      uri: map['uri'] as String,
      cachedAt: map['cachedAt'] as int?,
      modifiedAt: map['modifiedAt'] as int? ?? -1,
      rawData: map['rawData'] != null ? (map['rawData'] as Uint8List) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CachedImage &&
        other.localPath == localPath &&
        other.uri == uri &&
        other.cachedAt == cachedAt &&
        other.modifiedAt == modifiedAt &&
        other.rawData == rawData;
  }

  @override
  int get hashCode {
    return localPath.hashCode ^
        uri.hashCode ^
        cachedAt.hashCode ^
        modifiedAt.hashCode ^
        rawData.hashCode;
  }

  @override
  String toString() {
    return 'CachedImage(localPath: $localPath, uri: $uri, cachedAt: $cachedAt, modifiedAt: $modifiedAt, rawData: $rawData)';
  }
}

class CachedImageAdapter extends TypeAdapter<CachedImage> {
  @override
  CachedImage read(BinaryReader reader) {
    return CachedImage.fromMap(reader.read() as Map<String, dynamic>);
  }

  @override
  // TODO: implement typeId
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, CachedImage obj) {
    writer.write(obj.toMap());
  }
}
