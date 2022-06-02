import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_cached_image/src/cache_options.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager.dart';
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

  /// Default: the default Firebase app. Specifies a custom Firebase app to make the request to the bucket from
  final FirebaseApp? firebaseApp;

  /// The Url of the Cloud Storage image
  ///
  /// example: gs://bucket_f233/logo.jpg
  final String? firebaseUrl;

  /// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
  ///
  /// You need to specify [firebaseUrl] or [ref]. [firebaseUrl] must start with 'gs://'.
  /// If you passed both then [ref] will be used. Both [firebaseUrl] and [ref] can not be null.
  ///
  /// you can control how file gets fetched and cached by passing [options].
  ///
  /// ex:
  ///
  /// ```
  ///Image(
  ///  image: FirebaseImageProvider(
  ///    firebaseUrl: "gs://bucket_f233/logo.jpg",
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
    this.firebaseUrl,
    this.ref,
    this.options,
    this.scale = 1.0,
    this.maxSize,
    this.firebaseApp,
  }) : assert(firebaseUrl != null || ref != null, "provide firebaseUrl or ref");

  @override
  ImageStreamCompleter load(FirebaseImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: key._codec(decode),
      scale: key.scale,
      debugLabel: key.firebaseUrl ?? key.ref.toString(),
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
    await FirebaseCacheManager.initialise();
    final image = await FirebaseCacheManager.instance.getSingleFile(
      firebaseUrl: firebaseUrl,
      maxSize: maxSize,
      ref: ref,
      options: options,
      firebaseApp: firebaseApp,
    );
    return image.rawData!;
  }

  @override
  Future<FirebaseImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImageProvider>(this);
  }

  @override
  String toString() {
    return 'FirebaseImageProvider(settings: $options, ref: $ref, maxSize: $maxSize, scale: $scale, firebaseApp: $firebaseApp, firebaseUrl: $firebaseUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseImageProvider &&
        other.options == options &&
        other.ref == ref &&
        other.maxSize == maxSize &&
        other.scale == scale &&
        other.firebaseApp == firebaseApp &&
        other.firebaseUrl == firebaseUrl;
  }

  @override
  int get hashCode {
    return hashValues(
      options.hashCode,
      ref.hashCode,
      maxSize.hashCode,
      scale.hashCode,
      firebaseApp.hashCode,
      firebaseUrl.hashCode,
    );
  }
}
