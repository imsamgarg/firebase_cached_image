import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

Uri getUriFromRef(Reference ref) {
  final link = "gs://${ref.bucket}/${ref.fullPath}";
  return Uri.parse(link);
}

FirebaseStorage getStorageFromUri(Uri uri, FirebaseApp? app) {
  return FirebaseStorage.instanceFor(app: app, bucket: getBucketFromUri(uri));
}

String getBucketFromUri(Uri uri) => '${uri.scheme}://${uri.authority}';

Reference getRefFromUri(Uri uri, FirebaseApp? app) {
  return getStorageFromUri(uri, app).ref(uri.path);
}

String getUniqueId(String url) {
  return const Uuid().v5(Uuid.NAMESPACE_URL, url);
}
