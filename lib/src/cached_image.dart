// ignore_for_file: avoid_dynamic_calls

import 'dart:typed_data';

import 'package:hive/hive.dart';

class CachedImage {
  final String id;
  final String fullLocalPath;
  final String uri;
  final int? cachedAt;
  final int modifiedAt;
  final Uint8List? rawData;
  CachedImage({
    required this.id,
    required this.fullLocalPath,
    required this.uri,
    this.cachedAt,
    required this.modifiedAt,
    this.rawData,
  });

  CachedImage copyWith({
    String? id,
    String? fullLocalPath,
    String? uri,
    int? cachedAt,
    int? modifiedAt,
    Uint8List? rawData,
  }) {
    return CachedImage(
      id: id ?? this.id,
      fullLocalPath: fullLocalPath ?? this.fullLocalPath,
      uri: uri ?? this.uri,
      cachedAt: cachedAt ?? this.cachedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullLocalPath': fullLocalPath,
      'uri': uri,
      'cachedAt': cachedAt,
      'modifiedAt': modifiedAt,
      'rawData': rawData,
    };
  }

  factory CachedImage.fromMap(dynamic map) {
    return CachedImage(
      id: map['id'] as String,
      fullLocalPath: map['fullLocalPath'] as String,
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
        other.id == id &&
        other.fullLocalPath == fullLocalPath &&
        other.uri == uri &&
        other.cachedAt == cachedAt &&
        other.modifiedAt == modifiedAt &&
        other.rawData == rawData;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullLocalPath.hashCode ^
        uri.hashCode ^
        cachedAt.hashCode ^
        modifiedAt.hashCode ^
        rawData.hashCode;
  }

  @override
  String toString() {
    return 'CachedImage(id: $id, fullLocalPath: $fullLocalPath, uri: $uri, cachedAt: $cachedAt, modifiedAt: $modifiedAt, rawData: $rawData)';
  }
}

class CachedImageAdapter extends TypeAdapter<CachedImage> {
  @override
  CachedImage read(BinaryReader reader) {
    return CachedImage.fromMap(reader.read());
  }

  @override
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, CachedImage obj) {
    writer.write(obj.toMap());
  }
}
