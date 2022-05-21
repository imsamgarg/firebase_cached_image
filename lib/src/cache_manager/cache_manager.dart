abstract class BaseCacheManager {
  Future<BaseCacheManager> init();

  Future dispose();
}

//Stub Class
class CacheManager extends BaseCacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
