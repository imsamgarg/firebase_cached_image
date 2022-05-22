library firebase_cached_image;

import 'package:firebase_cached_image/src/cache_manager/cache_manager.dart'
    if (dart.library.html) 'package:firebase_cached_image/src/cache_manager/web_cache_manager.dart'
    if (dart.library.io) 'package:firebase_cached_image/src/cache_manager/mobile_cache_manager.dart';
import 'package:firebase_cached_image/src/cache_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part '/src/firebase_cached_image.dart';
part '/src/image_provider.dart';
