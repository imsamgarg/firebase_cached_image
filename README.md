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
    FirebaseUrl("gs://bucket_f233/logo.jpg")
  ),
),
```

You can alter default caching behaviour by passing `CacheOptions` to provider.

```dart
Image(
  image: FirebaseImageProvider(
    FirebaseUrl("gs://bucket_f233/logo.jpg"),
    options: CacheOptions(
      // Source from image will be fetched 
      //
      // Default [Source.cacheServer]
      source: Source.server,
    ),
  ),
),
```

By default it will first try to fetch the image from cache, if image exists then it will be returned otherwise image will be fetched from server and then cached.

If you want to always fetch latest image from server then pass `Source.server` to `CacheOptions.source`.

```dart
  source: Source.server,
```

If you want to fetch image from server only if it is updated after last fetched then set `checkForMetadataChange` to `true`.

```dart
  checkForMetadataChange: true,
```

By default image fetched from cache will be returned immediately and then server call will be made for checking if the file is updated and then latest image will be cached in background.If you want server call to be made first then set `metadataRefreshInBackground` to `false`.

```dart
options: CacheOptions(
  checkForMetadataChange: true,
  metadataRefreshInBackground: false,
),
```

Image updation is checked by fetching image's metadata from server then comparing to cached image's metadata.

Note: Metadata retrieval is a Class B operation in google cloud storage. you will be charged for that. Check pricing here (https://cloud.google.com/storage/pricing#price-tables) .Google does offer 50,000 free Class B operations per month.

---

## Firebase Cache Manager

if you want to work with any type of cloud storage file and want more functionality then use `FirebaseCacheManager`.

Download and cache any file.

```dart
final file = await FirebaseCacheManager().getSingleFile(
  FirebaseUrl("gs://bucket_f233/doc.docx"),
);
print(file); // Cached file's path, can be used for sharing file
```

Download and cache file before use. Can be useful for caching frequently used image at app's load time.

```dart
await FirebaseCacheManager().preCache(
  url: FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
```

Refresh already cached file..
  
Checks if the file has been updated in server, then download the file if it has been updated and saves it to cache.

```dart
await FirebaseCacheManager().refreshCachedFile(
  url: FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
);
```

Delete specific file from cache.

```dart
await FirebaseCacheManager().delete(
  url: FirebaseUrl("gs://bucket_f233/logo.jpg"),
);
```

Clear all the cache.

```dart
await FirebaseCacheManager().clearCache();
```

Use custom sub-directory to save files in desired directory in system's temporary directory

```dart
final manager = FirbaseCacheManager(subDir: "profile_pictures");
```

Also helpful in saving files in multiple folders

```dart
final profilePicturesCacheManager = FirbaseCacheManager(subDir: "profile_pictures");
final postsCacheManager = FirbaseCacheManager(subDir: "posts");

// Only delete files in posts directory
await postsCacheManger.clearCache();

```

_No support for caching in web, everything will be downloaded from server._
