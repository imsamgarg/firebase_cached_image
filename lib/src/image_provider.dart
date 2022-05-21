part of 'firebase_cached_image.dart';

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
