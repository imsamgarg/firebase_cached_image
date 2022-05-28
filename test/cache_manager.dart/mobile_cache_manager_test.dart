// import 'package:firebase_cached_image/src/cache_manager/mobile_cache_manager.dart';
// import 'package:firebase_cached_image/src/cached_image.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hive/hive.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';

// import 'mobile_cache_manager_test.mocks.dart';

// @GenerateMocks([Box<CachedImage>, HiveInterface, CachedImageAdapter])
// void main() {
//   late final CacheManager manager;
//   late final MockCachedImageAdapter mockAdapter;
//   late final MockHiveInterface mockHiveInterface;
//   const String appDir = "firebase_cached_image";

//   setUp(() async {
//     mockHiveInterface = MockHiveInterface();
//     mockAdapter = MockCachedImageAdapter();
//     when(mockHiveInterface.openBox<CachedImage>("images_box"))
//         .thenAnswer((_) => Future.value(MockBox<CachedImage>()));

//     manager = await CacheManager().test(appDir, mockHiveInterface, mockAdapter);
//   });

//   test("join fullpath", () {
//     String path = manager.getFullFilePath("hello");
//     expect(path, "$appDir/hello");

//     manager.setAppDir("hello/");
//     path = manager.getFullFilePath("hello");
//     expect(path, "hello/hello");

//     manager.setAppDir("hello/");
//     path = manager.getFullFilePath("hello/");
//     expect(path, "hello/hello/");

//     manager.setAppDir("hello");
//     path = manager.getFullFilePath("hello");
//     expect(path, "hello/hello");

//     manager.setAppDir("hello/");
//     path = manager.getFullFilePath("/hello");
//     expect(path, "hello/hello");

//     manager.setAppDir("hello");
//     path = manager.getFullFilePath("/hello");
//     expect(path, "hello/hello");
//   });
// }
