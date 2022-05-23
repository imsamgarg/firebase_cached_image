import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseImageProvider extends ImageProvider<FirebaseImageProvider> {
  @override
  ImageStreamCompleter load(FirebaseImageProvider key, DecoderCallback decode) {
    throw UnimplementedError();
  }

  @override
  Future<FirebaseImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImageProvider>(this);
  }
}
