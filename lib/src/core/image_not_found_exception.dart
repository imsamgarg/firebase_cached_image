import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/services.dart';

class ImageNotFoundException {
  final FirebaseUrl firebaseUrl;
  final PlatformException originalException;
  final StackTrace originalStackTrace;

  const ImageNotFoundException(
    this.firebaseUrl,
    this.originalException,
    this.originalStackTrace,
  );

  @override
  String toString() => 'ImageNotFoundException(firebaseUrl: $firebaseUrl)';
}
