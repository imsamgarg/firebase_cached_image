import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// The FirebaseUrl of the Cloud Storage image
class FirebaseUrl {
  final Uri url;
  final Reference ref;
  final String uniqueId;

  /// The FirebaseUrl of the Cloud Storage image
  ///
  /// ```
  /// FirebaseUrl("gs://bucket_f233/logo.jpg")
  /// FirebaseUrl("https://firebasestorage.googleapis.com/b/bucket/o/logo.jpg")
  ///
  /// ```
  /// The [url] can either be a HTTP or Google Storage URL pointing to an object.
  /// You can specify [FirebaseApp] if you are multiple firebase projects in app
  ///
  ///
  /// Use [FirebaseUrl.fromReference] if you want to use reference directly.
  factory FirebaseUrl(String url, {FirebaseApp? app}) {
    final _url = Uri.parse(url);
    final ref = getRefFromUrl(url, app);
    final urlStr = _url.toString();
    final String uniqueId = getUniqueId(urlStr) + path.extension(urlStr);

    return FirebaseUrl._(_url, ref, uniqueId);
  }

  const FirebaseUrl._(this.url, this.ref, this.uniqueId);

  /// Initialize from [Reference]..
  /// ```
  /// FirebaseUrl.fromReference(FirebaseStorage.instance.ref("images/image.jpg"));
  /// ```
  factory FirebaseUrl.fromReference(Reference ref) {
    final url = getUrlFromRef(ref);
    final urlStr = url.toString();
    final String uniqueId = getUniqueId(urlStr) + path.extension(urlStr);

    return FirebaseUrl._(url, ref, uniqueId);
  }

  @override
  String toString() => 'FirebaseUrl(url: $url, ref: $ref, uniqueId: $uniqueId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseUrl &&
        other.url == url &&
        other.ref == ref &&
        other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => Object.hash(url, ref, uniqueId);
}
