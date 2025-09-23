// ignore_for_file: avoid_dynamic_calls

import 'dart:typed_data';

class CachedObject {
  final String id;
  final String? fullLocalPath;
  final String url;
  final int modifiedAt;
  final Duration? cacheTime;
  final Uint8List? rawData;

  const CachedObject({
    required this.id,
    this.fullLocalPath,
    required this.url,
    required this.modifiedAt,
    this.cacheTime,
    this.rawData,
  });

  CachedObject copyWith({
    String? id,
    String? fullLocalPath,
    String? uri,
    int? modifiedAt,
    Uint8List? rawData,
    Duration? cacheTime,
  }) {
    return CachedObject(
      id: id ?? this.id,
      fullLocalPath: fullLocalPath ?? this.fullLocalPath,
      url: uri ?? url,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rawData: rawData ?? this.rawData,
      cacheTime: cacheTime ?? this.cacheTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullLocalPath': fullLocalPath,
      'uri': url,
      'modifiedAt': modifiedAt,
      if (rawData != null) 'rawData': rawData,
      if (cacheTime != null) 'cacheTime': cacheTime!.inSeconds,
    };
  }

  factory CachedObject.fromMap(Map<String, dynamic> map) {
    return CachedObject(
      id: map['id'] as String,
      fullLocalPath: map['fullLocalPath'] as String?,
      url: map['uri'] as String,
      modifiedAt: map['modifiedAt'] as int? ?? -1,
      rawData: map['rawData'] != null ? (map['rawData'] as Uint8List) : null,
      cacheTime: map['cacheTime'] != null
          ? (Duration(seconds: map['cacheTime'] as int))
          : null,
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
        other.rawData == rawData &&
        other.cacheTime == cacheTime;
  }

  @override
  int get hashCode {
    return Object.hash(id, fullLocalPath, url, modifiedAt, rawData, cacheTime);
  }

  @override
  String toString() => 'CachedImage(${toMap()})';
}
