# Firebase_Cached_Image

Cache Manager and Cached ImageProvider for Firebase Cloud Storage Objects.

## Set up

Setup firebase (https://firebase.google.com/docs/flutter/setup?platform=ios).

## Firebase Image Provider

If you want to show image from your cloud storage then use `Image` Widget and pass `FirebaseImageProvider` as `ImageProvider` to image argument. In `FirebaseImageProvider` pass either `FirebaseUrl` or `Reference` pointing to image in cloud storage.
`FirebaseUrl` is a class containing Google Storage Url String ex. `FirebaseUrl(gs://bucket_f233/logo.jpg)`.

```dart
Image(
  image: FirebaseImageProvider(
    url: FirebaseUrl("gs://bucket_f233/logo.jpg"),
    //Or 
    ref: FirebaseStorage.instance.ref().child("logo.png"),
  ),
),
```

You can alter default caching behaviour by passing `CacheOptions` to provider.

```dart
Image(
  image: FirebaseImageProvider(
    url: FirebaseUrl("gs://bucket_f233/logo.jpg"),
    options: CacheOptions(
      // For Disabling Caching
      shouldCache: false,
      // Source from image will be fetched by default: cacheServer
      source: Source.cacheServer,
    ),
  ),
),
```

By default it will first try to fetch the image from cache, if image exists then it will be returned otherwise image will be fetched from server and then cached.

If you want to always fetch latest image from server then pass `Source.server` to `CacheOptions.source`.

```dart
  source: Source.server,
```

If you want to fetch image from server only it is updated after last fetched then pass `Source.cacheServerByMetadata`.


```dart
  source: Source.cacheServerByMetadata,
```

By default image fetched from cach will be returned immediately then server call will be made and then latest image will be cached in background.If you want that server call will be made first then set `metadataRefreshInBackground` to `false`.


```dart
options: CacheOptions(
  source: Source.cacheServerByMetadata,
  metadataRefreshInBackground: false,
),
```

Image updation is checked by fetching image's metadata from server then comparing to cached image's metadata.

Note: Metadata retrieval is a Class B operation in google cloud storage. you will be charged for that. Check pricing here (https://cloud.google.com/storage/pricing#price-tables).Google does offer 50,000 free Class B operations per month.



----------

## Firebase Cache Manager

if you want to work with any type of cloud storage file and want more functionality then use `FirebaseCacheManager`.

### Set Up:

Initialize FirebaseCachedImage instance in main function.

```dart
await FirebaseCacheManager.initialize();
```

Download and cache any file.

*`getSingleFile` method's api is almost similar to `FirebaseImageProvider`'s.*

```dart
final file = await FirebaseCacheManager.instance.getSingleFile(
  url: FirebaseUrl("gs://bucket_f233/doc.docx"),
);
print(file.fullLocalPath); // Cached file's path, can be used for sharing file
print(file.rawData); // File's bytes (Uint8List)
```

Download and cache file before use. Can be useful for caching frequently used image at app's load time. 

```dart
await FirebaseCacheManager.instance.preCache(
  url: FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
);
```

Upload file and then save it to cache for later use.

```dart
final bytes = await File("path/image").readAsBytes();
await FirebaseCacheManager.instance.uploadAndCache(
  ref: FirebaseStorage.instance.ref().child("logo.png"),
  bytes: bytes,
  // Use this callback for listening to upload events
  uploadTaskCallback: (task) {
    task.snapshotEvents.listen((event) => print(event.bytesTransferred));
    return task;
  },
);
```

Delete specific file from cache.

```dart
await FirebaseCacheManager.instance.delete(
  url: FirebaseUrl("gs://bucket_f233/logo.jpg"),
);
```

Clear all the cache.

```dart
await FirebaseCacheManager.instance.clearCache();
```

You can also change global cacheOptions. `FirebaseImageProvider` use this cacheOptions too.

```dart
FirebaseCacheManager.instance.cacheOptions = CacheOptions(
  shouldCache: false,
  source: Source.server,
);
```
----------
*No support for caching in web, everything will be downloaded from server.*
