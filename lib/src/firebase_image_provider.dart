import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
class FirebaseImageProvider extends ImageProvider<FirebaseImageProvider> {
  /// Control how image gets fetched and cached
  ///
  /// by default it uses cacheOptions from [FirebaseCacheManager] class
  final CacheOptions? options;

  /// Cloud Storage reference to the object in the storage.
  final Reference? ref;

  /// Default: 10MB. The maximum size in bytes to be allocated in the device's memory for the image.
  final int? maxSize;

  /// Default: 1.0. The scale to display the image at.
  final double scale;

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
  final FirebaseUrl? url;

  /// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
  ///
  /// You need to specify [url] or [ref]. If you passed both then [ref] will be used. Both [url] and [ref] can not be null.
  ///
  /// you can control how file gets fetched and cached by passing [options].
  ///
  /// ex:
  ///
  /// ```
  ///Image(
  ///  image: FirebaseImageProvider(
  ///    firebaseUrl: FirebaseUrl("gs://bucket_f233/logo.jpg"),
  ///
  ///    options: CacheOptions(
  ///      source: Source.server,
  ///    ),
  ///  ),
  ///
  ///  // you will need to use [Image.frameBuilder] for showing any widget while image is loading.
  ///  // [loadingBuilder] won't work because of firebase_storage implementation.
  ///  frameBuilder: (_, child, frame, __) {
  ///    if (frame == null) return child;
  ///
  ///    return const CircularProgressIndicator();
  ///  },
  /// ),
  /// ```
  FirebaseImageProvider({
    this.url,
    this.ref,
    this.options,
    this.scale = 1.0,
    this.maxSize,
  }) : assert(url != null || ref != null, "provide url or ref");

  @override
  ImageStreamCompleter load(FirebaseImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: key._codec(decode),
      scale: key.scale,
      debugLabel: key.url?.url ?? key.ref.toString(),
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<FirebaseImageProvider>('Image provider', this),
        DiagnosticsProperty<FirebaseImageProvider>('Image key', key),
      ],
    );
  }

  Future<Codec> _codec(DecoderCallback decode) async {
    return decode(await _fetchImage());
  }

  Future<Uint8List> _fetchImage() async {
    await FirebaseCacheManager.initialize();
    final image = await FirebaseCacheManager.instance.getSingleFile(
      url: url,
      maxSize: maxSize,
      ref: ref,
      options: options,
    );
    return image.rawData!;
  }

  @override
  Future<FirebaseImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImageProvider>(this);
  }

  @override
  String toString() {
    return 'FirebaseImageProvider(settings: $options, ref: $ref, maxSize: $maxSize, scale: $scale, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseImageProvider &&
        other.options == options &&
        other.ref == ref &&
        other.maxSize == maxSize &&
        other.scale == scale &&
        other.url == other.url;
  }

  @override
  int get hashCode {
    return hashValues(
      options.hashCode,
      ref.hashCode,
      maxSize.hashCode,
      scale.hashCode,
      url.hashCode,
    );
  }
}
