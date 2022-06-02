// ignore_for_file: avoid_dynamic_calls

import 'dart:typed_data';

class CachedObject {
  final String id;
  final String? fullLocalPath;
  final String uri;
  final int modifiedAt;
  final int? lastAccessedAt;
  final Uint8List? rawData;
  CachedObject({
    required this.id,
    this.fullLocalPath,
    required this.uri,
    required this.modifiedAt,
    this.lastAccessedAt,
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
      uri: uri ?? this.uri,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullLocalPath': fullLocalPath,
      'uri': uri,
      'modifiedAt': modifiedAt,
      'lastAccessedAt': lastAccessedAt,
      if (rawData != null) 'rawData': rawData,
    };
  }

  factory CachedObject.fromMap(dynamic map) {
    return CachedObject(
      id: map['id'] as String,
      fullLocalPath: map['fullLocalPath'] as String?,
      uri: map['uri'] as String,
      modifiedAt: map['modifiedAt'] as int? ?? -1,
      rawData: map['rawData'] != null ? (map['rawData'] as Uint8List) : null,
      lastAccessedAt: (map['lastAccessedAt'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CachedObject &&
        other.id == id &&
        other.fullLocalPath == fullLocalPath &&
        other.uri == uri &&
        other.modifiedAt == modifiedAt &&
        other.lastAccessedAt == lastAccessedAt &&
        other.rawData == rawData;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullLocalPath.hashCode ^
        uri.hashCode ^
        modifiedAt.hashCode ^
        lastAccessedAt.hashCode ^
        rawData.hashCode;
  }

  @override
  String toString() {
    return 'CachedImage(id: $id, fullLocalPath: $fullLocalPath, uri: $uri, modifiedAt: $modifiedAt, lastAccessedAt: $lastAccessedAt, rawData: $rawData)';
  }
}
