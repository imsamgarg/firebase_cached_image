import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const _kImageCacheDir = "flutter_cached_image";
const _kImageCacheBox = "images_box";

class CacheManager extends BaseCacheManager {
  String? _appDir;
  late final Box<CachedImage> _box;

  @override
  Future<CacheManager> init() async {
    if (_appDir != null) {
      _appDir = await _getCacheDir();
    }

    Hive
      ..init(_appDir)
      ..registerAdapter(CachedImageAdapter());

    _box = await Hive.openBox<CachedImage>(_kImageCacheBox);
    return this;
  }

  //Only For Testing
  @visibleForTesting
  Future<CacheManager> test(
    String appDir,
    HiveInterface hive,
    TypeAdapter adapter,
  ) async {
    _appDir = appDir;
    hive
      ..init(appDir)
      ..registerAdapter(adapter);

    _box = await hive.openBox<CachedImage>(_kImageCacheBox);
    return this;
  }

  @visibleForTesting
  String setAppDir(String dir) => _appDir = dir;

  Future<String> _getCacheDir() async {
    final _dir = await getApplicationDocumentsDirectory();
    return join(_dir.path, _kImageCacheDir);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.flush();
    Directory(_appDir!).deleteSync(recursive: true);
  }

  @override
  Future<CachedImage?> delete(String id) async {
    final image = _box.get(id);
    if (image == null) return null;

    final isExist = File(image.fullLocalPath).existsSync();
    if (isExist) {
      File(image.fullLocalPath).deleteSync();
    }

    await _box.delete(id);
    await _box.flush();
    return image;
  }

  @override
  Future<CachedImage?> get(String id) {
    final image = _box.get(id);
    if (image == null) return Future.value();

    final isExist = File(image.fullLocalPath).existsSync();
    if (!isExist) return Future.value();

    final bytes = File(image.fullLocalPath).readAsBytesSync();
    return Future.value(image.copyWith(rawData: bytes));
  }

  @visibleForTesting
  String getFullFilePath(String fileName) {
    final _fileName =
        fileName.startsWith("/") ? fileName.substring(1) : fileName;
    return join(_appDir!, _fileName);
  }

  @override
  Future<void> put(
    String id, {
    required String uri,
    required int modifiedAt,
    required Uint8List bytes,
    int? cachedAt,
  }) async {
    final localPath = getFullFilePath(id);
    final _imageForDb = CachedImage(
      id: id,
      fullLocalPath: localPath,
      uri: uri,
      modifiedAt: modifiedAt,
      cachedAt: cachedAt,
    );

    File(localPath).writeAsBytesSync(bytes);

    await _box.put(id, _imageForDb);
    await _box.flush();
  }
}
