import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';

class FirebaseCacheManager extends BaseFirebaseCacheManager {
  FirebaseCacheManager({super.subDir});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
