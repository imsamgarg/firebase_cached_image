import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

Uri getUrlFromRef(Reference ref) {
  final link = "gs://${ref.bucket}/${ref.fullPath}";
  return Uri.parse(link);
}

String getBucketFromUrl(Uri url) => '${url.scheme}://${url.authority}';

Reference getRefFromUrl(String url, FirebaseApp? app) {
  return FirebaseStorage.instanceFor(app: app).refFromURL(url);
}

String getUniqueId(String url) {
  return const Uuid().v5(Uuid.NAMESPACE_URL, url);
}
