import 'package:file/memory.dart';
import 'package:firebase_cached_image/src/fs_manager/fs_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FsManager', () {
    late FsManager fsManager;
    late MemoryFileSystem fs;
    const subDir = 'test';

    setUp(() {
      fs = MemoryFileSystem();
      getTempDir = () async => fs.systemTempDirectory;
      fsManager = FsManager.test(fs, subDir: subDir);
    });

    tearDown(() {
      cachedAppDirPaths.clear();
    });

    test('getFile', () async {
      final file = await fsManager.getFile('test.txt');
      expect(file.path, contains(subDir));
      expect(file.path, contains('test.txt'));
    });

    test('createFile', () async {
      final file = await fsManager.createFile('test.txt');
      expect(file.path, contains(subDir));
      expect(file.path, contains('test.txt'));
      expect(await file.exists(), isTrue);
    });

    test('deleteFile', () async {
      final file = await fsManager.createFile('test.txt');
      expect(await file.exists(), isTrue);

      await fsManager.deleteFile('test.txt');
      expect(await file.exists(), isFalse);
    });

    test('getTempDir', () async {
      final tempDir = await getTempDir();
      expect(tempDir.path, contains('tmp'));
    });

    test('getLocalDir', () async {
      final localDir = await getLocalDir(subDir, fs);

      expect(fs.directory(localDir).existsSync(), isTrue);
      expect(localDir, contains(subDir));
    });

    test('getLocalDir with cachedAppDirPaths', () async {
      cachedAppDirPaths.clear();
      int counter = 0;
      getTempDir = () async {
        counter++;
        return fs.systemTempDirectory;
      };

      final localDir = await getLocalDir(subDir, fs);
      final cachedLocalDir = await getLocalDir(subDir, fs);
      expect(localDir, equals(cachedLocalDir));
      expect(cachedAppDirPaths.length, 1);
      expect(counter, 1); // Second hit must be catched value
    });

    test('FsManager`s dir path', () async {
      final dirPath = await fsManager.dirPath;
      expect(path.basename(dirPath), contains(subDir));
    });

    test('File exists', () async {
      final file = await fsManager.createFile('test.txt');
      expect(await fsManager.fileExists('test.txt'), isTrue);

      await fsManager.deleteFile('test.txt');
      expect(await fsManager.fileExists('test.txt'), isFalse);
    });

    test('deleteAllFiles', () async {
      await fsManager.createFile('test1.txt');
      await fsManager.createFile('test2.txt');
      await fsManager.createFile('test3.txt');

      expect(await fsManager.fileExists('test1.txt'), isTrue);
      expect(await fsManager.fileExists('test2.txt'), isTrue);
      expect(await fsManager.fileExists('test3.txt'), isTrue);

      await fsManager.deleteAllFiles();

      expect(await fsManager.fileExists('test1.txt'), isFalse);
      expect(await fsManager.fileExists('test2.txt'), isFalse);
      expect(await fsManager.fileExists('test3.txt'), isFalse);
    });

    test('FsManager with different subDir', () async {
      final fsManager2 = FsManager.test(fs, subDir: 'test2');
      final dirPath = await fsManager2.dirPath;
      expect(path.basename(dirPath), contains('test2'));
    });
  });
}
