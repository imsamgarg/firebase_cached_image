import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

@visibleForTesting
final cachedAppDirPaths = <String, String>{};

@visibleForTesting
Future<io.Directory> Function() getTempDir = () {
  return getTemporaryDirectory();
};

@visibleForTesting
Future<String> getLocalDir(String _subDir, FileSystem fs) async {
  String _localDir;

  if (cachedAppDirPaths.containsKey(_subDir)) {
    _localDir = cachedAppDirPaths[_subDir]!;
  } else {
    final _cacheDir = await getTempDir();
    _localDir = fs.directory(_cacheDir.path).childDirectory(_subDir).path;
    cachedAppDirPaths.putIfAbsent(_subDir, () => _localDir);
  }

  await fs.directory(_localDir).create();

  return _localDir;
}

class FsManager {
  final FileSystem _fs;
  final Future<String> _dirPath;

  FsManager({required String subDir})
      : _fs = const LocalFileSystem(),
        _dirPath = getLocalDir(subDir, const LocalFileSystem());

  @visibleForTesting
  FsManager.test(this._fs, {required String subDir})
      : _dirPath = getLocalDir(subDir, _fs);

  @visibleForTesting
  Future<String> get dirPath => _dirPath;

  Future<File> getFile(String fileName) async {
    final dir = await _dirPath;
    return _fs.directory(dir).childFile(fileName);
  }

  Future<File> createFile(String fileName) async {
    return getFile(fileName).then((file) => file.create());
  }

  Future<void> deleteFile(String fileName) async {
    return getFile(fileName).then((file) => file.delete());
  }

  Future<bool> fileExists(String fileName) async {
    return getFile(fileName).then((file) => file.exists());
  }

  Future<void> deleteAllFiles() async {
    final dir = await _dirPath;
    final fsDir = _fs.directory(dir);

    await fsDir.delete(recursive: true);
    await fsDir.create(recursive: true);
  }

  @visibleForTesting
  Future<String> getFullLocalPath(String fileName) async {
    return getFile(fileName).then((file) => file.path);
  }
}
