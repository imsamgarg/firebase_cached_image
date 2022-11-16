// ignore_for_file: avoid_dynamic_calls

import 'dart:typed_data';

class CachedObject {
  final String id;
  final String? fullLocalPath;
  final String url;
  final int modifiedAt;
  final Uint8List? rawData;
  CachedObject({
    required this.id,
    this.fullLocalPath,
    required this.url,
    required this.modifiedAt,
    this.rawData,
  });

  CachedObject copyWith({
    String? id,
    String? fullLocalPath,
    String? uri,
    int? modifiedAt,
    int? lastAccessedAt,
    Uint8List? rawData,
  }) {
    return CachedObject(
      id: id ?? this.id,
      fullLocalPath: fullLocalPath ?? this.fullLocalPath,
      url: uri ?? url,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullLocalPath': fullLocalPath,
      'uri': url,
      'modifiedAt': modifiedAt,
      if (rawData != null) 'rawData': rawData,
    };
  }

  factory CachedObject.fromMap(dynamic map) {
    return CachedObject(
      id: map['id'] as String,
      fullLocalPath: map['fullLocalPath'] as String?,
      url: map['uri'] as String,
      modifiedAt: map['modifiedAt'] as int? ?? -1,
      rawData: map['rawData'] != null ? (map['rawData'] as Uint8List) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CachedObject &&
        other.id == id &&
        other.fullLocalPath == fullLocalPath &&
        other.url == url &&
        other.modifiedAt == modifiedAt &&
        other.rawData == rawData;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullLocalPath.hashCode ^
        url.hashCode ^
        modifiedAt.hashCode ^
        rawData.hashCode;
  }

  @override
  String toString() {
    return 'CachedImage(id: $id, fullLocalPath: $fullLocalPath, uri: $url, modifiedAt: $modifiedAt, rawData: $rawData)';
  }
}
