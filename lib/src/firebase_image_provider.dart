import 'dart:async';
import 'dart:ui';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
class FirebaseImageProvider extends ImageProvider<FirebaseImageProvider> {
  /// Control how image gets fetched and cached
  final CacheOptions options;

  /// Default: 10MB. The maximum size in bytes to be allocated in the device's memory for the image.
  final int maxSize;

  /// Default: 1.0. The scale to display the image at.
  final double scale;

  /// The FirebaseUrl of the Cloud Storage image
  ///
  /// example:
  /// ```
  /// FirebaseUrl("gs://bucket_f233/logo.jpg")
  /// FirebaseUrl("https://firebasestorage.googleapis.com/b/bucket/o/logo.jpg")
  /// FirebaseUrl.fromReference(FirebaseStorage.instance.ref("images/image.jpg"));
  /// ```
  ///
  /// you can specify [FirebaseApp] if you are multiple firebase projects in app
  /// ex:
  ///
  /// ```
  /// FirebaseUrl("gs://bucket_f233/logo.jpg", app: Firebase.app("app_name"));
  /// FirebaseUrl("https://firebasestorage.googleapis.com/b/bucket/o/logo.jpg", app: Firebase.app("app_name"));
  ///
  /// ```
  final FirebaseUrl firebaseUrl;

  /// Use this to save files in desired directory in system's temporary directory
  ///
  /// Default: ["flutter_cached_image"]
  final String _subDir;

  /// Fetch, cache and return ImageProvider for Cloud Storage Image Objects.
  ///
  /// You can control how file gets fetched and cached by passing [options].
  ///
  /// ex:
  ///
  /// ```
  /// Image(
  ///   image: FirebaseImageProvider(
  ///     FirebaseUrl("gs://your_bucket/your_image.jpg"),
  ///
  ///     // Specify CacheOptions to control file fetching and caching behavior.
  ///     options: const CacheOptions(
  ///       // Always fetch the latest file from the server and do not cache the file.
  ///       // Default is Source.cacheServer, which will try to fetch the image from the cache and then hit the server if the image is not found in the cache.
  ///       source: Source.server,
  ///
  ///       // Check if the image is updated on the server or not. If updated, then download the latest image; otherwise, use the cached image.
  ///       // Will only be used if the options.source is Source.cacheServer.
  ///       checkForMetadataChange: true,
  ///     ),
  ///
  ///     // Use this to save files in the desired directory in the system's temporary directory.
  ///     // Optional. Default is "flutter_cached_image".
  ///     subDir: "custom_cache_directory",
  ///   ),
  ///   errorBuilder: (context, error, stackTrace) {
  ///     // [ImageNotFoundException] will be thrown if the image does not exist on the server.
  ///     if (error is ImageNotFoundException) {
  ///       // Handle ImageNotFoundException and show a user-friendly message.
  ///       return const Text('Image not found on Cloud Storage.');
  ///     } else {
  ///       // Handle other errors.
  ///       return Text('Error loading image: $error');
  ///     }
  ///   },
  ///   // The loading progress may not be accurate as Firebase Storage API
  ///   // does not provide a stream of bytes downloaded. The progress updates only at the start and end of the loading process.
  ///   loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
  ///     if (loadingProgress == null) {
  ///       // Show the loaded image if loading is complete.
  ///       return child;
  ///     } else {
  ///       // Show a loading indicator with progress information.
  ///       return CircularProgressIndicator(
  ///         value: loadingProgress.expectedTotalBytes != null
  ///             ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
  ///             : null,
  ///       );
  ///     }
  ///   },
  /// )
  /// ```
  FirebaseImageProvider(
    this.firebaseUrl, {
    this.options = const CacheOptions(),
    this.scale = 1.0,
    this.maxSize = 10485760,

    /// Use this to save files in desired directory in system's temporary directory
    ///
    /// Default: ["flutter_cached_image"]
    String? subDir,
  }) : _subDir = subDir ?? kDefaultImageCacheDir;

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

      final cachedObject =
          await FirebaseCacheManager(subDir: _subDir).getSingleObject(
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
    return 'FirebaseImageProvider(options: $options, maxSize: $maxSize, scale: $scale, firebaseUrl: $firebaseUrl, subDir: $_subDir)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseImageProvider &&
        other.options == options &&
        other.maxSize == maxSize &&
        other.scale == scale &&
        other.firebaseUrl == firebaseUrl &&
        other._subDir == _subDir;
  }

  @override
  int get hashCode {
    return Object.hash(
      options.hashCode,
      maxSize.hashCode,
      scale.hashCode,
      firebaseUrl.hashCode,
      _subDir.hashCode,
    );
  }
}
