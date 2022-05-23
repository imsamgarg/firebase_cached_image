import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_cached_image/src/cache_manager/base_cache_manager.dart';
import 'package:firebase_cached_image/src/cached_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const _kImageCacheDir = "flutter_cached_image";

class CacheSettings {
  final bool shouldCache;
  final CacheRefreshStrategy cacheRefreshStrategy;

  CacheSettings({
    this.shouldCache = true,
    this.cacheRefreshStrategy = CacheRefreshStrategy.byMetadata,
  });
}

enum CacheRefreshStrategy { byMetadata, never }

enum CacheOptions { server, cacheAndServer, cacheAndServerByMetadata }

class CacheManager extends BaseCacheManager {
  static String? _appDir;
  late final Box<CachedImage> _box;

  @override
  Future<BaseCacheManager> init() async {
    if (_appDir != null) {
      _appDir = await _getCacheDir();
    }

    Hive
      ..init(_appDir)
      ..registerAdapter(CachedImageAdapter());

    _box = await Hive.openBox<CachedImage>(kImageCacheBox);
    return this;
  }

  static Future<String> _getCacheDir() async {
    final _dir = await getApplicationDocumentsDirectory();
    return join(_dir.path, _kImageCacheDir);
  }

  @override
  Future<CachedImage> cacheImage(
    Uint8List? data, {
    required Uri uri,
    required Reference ref,
  }) async {
    final _time = DateTime.now();

    final localPath = _saveDataToDisk(data, ref);

    final _imageModel = CachedImage(
      uri: uri.toString(),
      modifiedAt: _time.millisecondsSinceEpoch,
      cachedAt: _time.millisecondsSinceEpoch,
      localPath: localPath,
    );

    _box.put(_imageModel.uri, _imageModel);
    await _box.flush();

    return _imageModel;
  }

  @override
  Future<Uint8List?> getFromCache(String localPath) {
    if (!File(localPath).existsSync()) return Future.value();

    return Future.value(File(localPath).readAsBytesSync());
  }

  String _saveDataToDisk(Uint8List? data, Reference ref) {
    final path = join(_appDir!, ref.fullPath);
    File(path).writeAsBytesSync(data!);
    return path;
  }

  @override
  Future<void> clearCache() async {
    await _box.clear();
    await _box.flush();
    return Directory(_appDir!).deleteSync();
  }

  @override
  Future<void> deleteFromCache(Uri uri) {
    final image = _box.get(uri.toString());
    if (image != null) {
      File(image.localPath).deleteSync();
    }

    _box.delete(uri.toString());
    return _box.flush();
  }

  @override
  Future dispose() => Hive.close();

  @override
  Future<CachedImage?> getCachedImageModel(String key) {
    return Future.value(_box.get(key));
  }

  @override
  Future<void> saveCachedImageModel(String key, CachedImage image) {
    return Future.value(_box.put(key, image));
  }
}
