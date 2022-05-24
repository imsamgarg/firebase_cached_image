import 'dart:typed_data';

import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageManager {
  final Reference reference;

  factory FirebaseStorageManager.fromUri(Uri uri, {FirebaseApp? app}) {
    final ref = getRefFromUri(uri, app);
    return FirebaseStorageManager._(ref);
  }

  FirebaseStorageManager.fromRef(this.reference);

  FirebaseStorageManager._(this.reference);

  Future<Uint8List?> get([int maxSize = 10485760]) {
    return reference.getData(maxSize);
  }

  Future<FullMetadata> getMetadata() => reference.getMetadata();

  Future<Uint8List?> getIfUpdated(
    int updatedAfter, [
    int maxSize = 10485760,
  ]) async {
    final metadata = await getMetadata();
    final updatedAt = metadata.updated?.millisecondsSinceEpoch;
    if (updatedAt == null || updatedAt <= updatedAfter) return null;

    return get(maxSize);
  }
}
