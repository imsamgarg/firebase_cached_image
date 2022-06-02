import 'package:firebase_cached_image/src/helper_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// The FirebaseUrl of the Cloud Storage image
class FirebaseUrl {
  /// The Url of the Cloud Storage image
  ///
  /// Must start with gs://
  /// ex: gs://bucket_f233/logo.jpg
  final String url;

  /// Default: the default Firebase app. Specifies a custom Firebase app to make the request to the bucket from
  final FirebaseApp? app;

  //parsed uri from firebase url
  final Uri parsedUri;

  /// The FirebaseUrl of the Cloud Storage image
  ///
  /// example:
  /// ```
  /// FirebaseUrl("gs://bucket_f233/logo.jpg")
  /// ```
  ///
  /// you can specify [FirebaseApp] if you are multiple firebase projects in app
  /// ex:
  ///
  /// ```
  /// FirebaseUrl("gs://bucket_f233/logo.jpg", app: Firebase.app("app_name"));
  ///
  /// ```
  FirebaseUrl(
    this.url, {
    this.app,
  }) : parsedUri = Uri.parse(url);

  FirebaseUrl copyWith({
    String? url,
    FirebaseApp? app,
  }) {
    return FirebaseUrl(
      url ?? this.url,
      app: app ?? this.app,
    );
  }

  Reference get ref => getRefFromUri(parsedUri, app);

  @override
  String toString() => 'FirebaseUrl(url: $url, app: $app)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseUrl && other.url == url && other.app == app;
  }

  @override
  int get hashCode => url.hashCode ^ app.hashCode;
}
