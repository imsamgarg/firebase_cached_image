import 'package:file/file.dart';
import 'package:firebase_cached_image/src/cloud_storage_manager/cloud_storage_manager.dart';
import 'package:firebase_cached_image/src/core/firebase_url.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NativeCloudStorageManager extends CloudStorageManager {
  Future<TaskSnapshot> writeToFile(
    FirebaseUrl firebaseUrl,
    File file,
  ) async {
    final task = await firebaseUrl.ref.writeToFile(file);

    return task;
  }
}
