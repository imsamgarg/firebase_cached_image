// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// The FirebaseUrl of the Cloud Storage image
class FirebaseUrl {
  // Parsed uri from firebase url
  final Uri url;
  final Reference ref;
  final String uniqueId;

  /// The FirebaseUrl of the Cloud Storage image
  ///
  /// ```
  /// FirebaseUrl("gs://bucket_f233/logo.jpg")
  /// ```
  /// you can specify [FirebaseApp] if you are multiple firebase projects in app
  ///
  ///
  /// Use [FirebaseUrl.fromReference] if you want to use reference directly.
  factory FirebaseUrl(
    String url, {
    FirebaseApp? app,
  }) {
    final uri = Uri.parse(url);
    final ref = getRefFromUrl(uri, app);
    final uniqueId = getUniqueId(uri.toString());
    return FirebaseUrl._(uri, ref, uniqueId);
  }

  FirebaseUrl._(this.url, this.ref, this.uniqueId);

  /// Initialize from [Reference]..
  /// ```
  /// FirebaseUrl.fromReference(FirebaseStorage.instance.ref("images/image.jpg"));
  /// ```
  factory FirebaseUrl.fromReference(Reference ref) {
    final url = getUrlFromRef(ref);
    final id = getUniqueId(url.toString());

    return FirebaseUrl._(url, ref, id);
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
  int get hashCode => url.hashCode ^ ref.hashCode ^ uniqueId.hashCode;
}
