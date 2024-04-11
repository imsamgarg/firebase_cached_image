import 'dart:typed_data';

import 'package:firebase_cached_image/src/core/firebase_url.dart';

class CloudStorageManager {
  Future<Uint8List?> downloadLatestFile(
    FirebaseUrl firebaseUrl, [
    int maxSize = 10485760,
  ]) {
    return firebaseUrl.ref.getData(maxSize);
  }

  Future<bool> isUpdated(
    FirebaseUrl firebaseUrl,
    int cachedFileModifiedAt,
  ) async {
    final metadata = await firebaseUrl.ref.getMetadata();
    final lastModified = metadata.updated;

    return (lastModified?.millisecondsSinceEpoch ?? 0) > cachedFileModifiedAt;
  }
}
