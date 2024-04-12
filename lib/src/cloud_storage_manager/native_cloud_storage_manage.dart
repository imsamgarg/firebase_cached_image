import 'package:file/file.dart';
import 'package:firebase_cached_image/src/cloud_storage_manager/cloud_storage_manager.dart';
import 'package:firebase_cached_image/src/core/firebase_url.dart';

class NativeCloudStorageManager extends CloudStorageManager {
  //* Dynamic is used to avoid returning DownloadTask in Test class
  Future<dynamic> writeToFile(
    FirebaseUrl firebaseUrl,
    File file,
  ) {
    return firebaseUrl.ref.writeToFile(file);
  }
}
