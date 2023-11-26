import 'dart:async';
import 'dart:ui';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
class FirebaseImageProvider extends ImageProvider<FirebaseImageProvider> {
  /// Control how image gets fetched and cached
  final CacheOptions options;

  final FirebaseCacheManager _cacheManager;

  /// Default: 10MB. The maximum size in bytes to be allocated in the device's memory for the image.
  final int maxSize;

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
  final FirebaseUrl firebaseUrl;

  /// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
  ///
  /// You can control how file gets fetched and cached by passing [options].
  ///
  /// ex:
  ///
  /// ```
  ///Image(
  ///  image: FirebaseImageProvider(
  ///    FirebaseUrl("gs://bucket_f233/logo.jpg"),
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
  FirebaseImageProvider(
    this.firebaseUrl, {
    this.options = const CacheOptions(),
    this.scale = 1.0,
    this.maxSize = 10485760,
    String? subDir,
  }) : _cacheManager = FirebaseCacheManager(subDir: subDir);

  @override
  ImageStreamCompleter loadImage(
    FirebaseImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, (buffer) => decode(buffer)),
      scale: key.scale,
      chunkEvents: chunkEvents.stream,
      debugLabel: key.firebaseUrl.url.toString(),
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<FirebaseImageProvider>('Image provider', this),
        DiagnosticsProperty<FirebaseImageProvider>('Image key', key),
      ],
    );
  }

  @override
  ImageStreamCompleter loadBuffer(
    FirebaseImageProvider key,
    DecoderBufferCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, (buffer) => decode(buffer)),
      scale: key.scale,
      chunkEvents: chunkEvents.stream,
      debugLabel: key.firebaseUrl.url.toString(),
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<FirebaseImageProvider>('Image provider', this),
        DiagnosticsProperty<FirebaseImageProvider>('Image key', key),
      ],
    );
  }

  Future<Codec> _loadAsync(
    FirebaseImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    Future<Codec> Function(ImmutableBuffer buffer) decode,
  ) async {
    try {
      chunkEvents.add(
        const ImageChunkEvent(
          cumulativeBytesLoaded: 0,
          expectedTotalBytes: null,
        ),
      );

      final cachedObject = await _cacheManager.getSingleObject(
        firebaseUrl,
        options: options,
      );

      final bytes = cachedObject.rawData;

      if (bytes == null || bytes.isEmpty) {
        throw Exception(
          "FirebaseImageProvider empty file: ${firebaseUrl.url}",
        );
      }

      chunkEvents.add(
        ImageChunkEvent(
          cumulativeBytesLoaded: bytes.length,
          expectedTotalBytes: bytes.length,
        ),
      );

      final buffer = await ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e, s) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });

      if (e is PlatformException) {
        final details = e.details;
        if (details is Map && details["code"] == "object-not-found") {
          throw ImageNotFoundException(firebaseUrl, e, s);
        }
      }

      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  Future<FirebaseImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImageProvider>(this);
  }

  @override
  String toString() {
    return 'FirebaseImageProvider(options: $options, maxSize: $maxSize, scale: $scale, firebaseUrl: $firebaseUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseImageProvider &&
        other.options == options &&
        other._cacheManager == _cacheManager &&
        other.maxSize == maxSize &&
        other.scale == scale &&
        other.firebaseUrl == firebaseUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      _cacheManager.hashCode,
      options.hashCode,
      maxSize.hashCode,
      scale.hashCode,
      firebaseUrl.hashCode,
    );
  }
}
