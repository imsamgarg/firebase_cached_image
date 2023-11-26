import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/services.dart';

class ImageNotFoundException {
  final FirebaseUrl firebaseUrl;
  final PlatformException originalExecption;
  final StackTrace originalStackTrace;

  ImageNotFoundException(
    this.firebaseUrl,
    this.originalExecption,
    this.originalStackTrace,
  );

  @override
  String toString() => 'ImageNotFoundException(firebaseUrl: $firebaseUrl)';
}
