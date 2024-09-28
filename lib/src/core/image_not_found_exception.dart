import 'package:firebase_cached_image/firebase_cached_image.dart';

class ImageNotFoundException {
  final FirebaseUrl firebaseUrl;
  final Object originalException;
  final StackTrace originalStackTrace;

  const ImageNotFoundException(
    this.firebaseUrl,
    this.originalException,
    this.originalStackTrace,
  );

  @override
  String toString() =>
      'ImageNotFoundException(firebaseUrl: $firebaseUrl, originalException: $originalException)';
}
