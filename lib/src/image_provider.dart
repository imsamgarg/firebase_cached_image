import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_cached_image/src/cache_settings.dart';
import 'package:firebase_cached_image/src/firebase_cached_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseImageProvider extends ImageProvider<FirebaseImageProvider> {
  final CacheSettings? settings;
  final Reference? ref;
  final int? maxSize;
  final double scale;
  final FirebaseApp? firebaseApp;
  final String? firebaseUrl;

  FirebaseImageProvider({
    this.firebaseUrl,
    this.ref,
    this.settings,
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
    return decode(await fetchImage());
  }

  @visibleForTesting
  Future<Uint8List> fetchImage() async {
    await FirebaseCachedImage.initialise();
    final bytes = await FirebaseCachedImage.instance.get(
      firebaseUrl: firebaseUrl,
      maxSize: maxSize,
      ref: ref,
      settings: settings,
      firebaseApp: firebaseApp,
    );
    return bytes!;
  }

  @override
  Future<FirebaseImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImageProvider>(this);
  }

  @override
  String toString() {
    return 'FirebaseImageProvider(settings: $settings, ref: $ref, maxSize: $maxSize, scale: $scale, firebaseApp: $firebaseApp, firebaseUrl: $firebaseUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FirebaseImageProvider &&
        other.settings == settings &&
        other.ref == ref &&
        other.maxSize == maxSize &&
        other.scale == scale &&
        other.firebaseApp == firebaseApp &&
        other.firebaseUrl == firebaseUrl;
  }

  @override
  int get hashCode {
    return settings.hashCode ^
        ref.hashCode ^
        maxSize.hashCode ^
        scale.hashCode ^
        firebaseApp.hashCode ^
        firebaseUrl.hashCode;
  }
}
