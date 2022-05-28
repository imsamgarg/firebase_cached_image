# Firebase_Cached_Image

Cache Manager and Cached ImageProvider for Firebase Cloud Storage Objects.

## Set up

Setup firebase (https://firebase.google.com/docs/flutter/setup?platform=ios).

Initialise FirebaseCachedImage instance in main function.

```dart
await FirebaseCachedImage.initialise();
```

## How To Use

If you want to show image from your cloud storage then use `Image` Widget and pass `FirebaseImageProvider` as `ImageProvider` to image argument. In `FirebaseImageProvider` pass either `firebaseUrl` or `ref` pointing to image in cloud storage.
`firebaseUrl` is a Google Storage Url ex. `gs://bucket_f233/logo.jpg`.

```dart
Image(
  image: FirebaseImageProvider(
    firebaseUrl: "gs://bucket_f233/logo.jpg",
  ),
),
```
Or
```dart
Image(
  image: FirebaseImageProvider(
    ref: FirebaseStorage.instance.ref().child("logo.png"),
  ),
),
```


## Source

By default it will first try to fetch the image from cache, if image exists then it will be returned otherwise image will be fetched from server and then cached.

You can change default behaviour by passing `CacheOptions` to `FirebaseImageProvider`

```dart
class CacheOptions {
  /// The source from which file gets fetched
  ///
  /// default: Source.cacheServer
  final Source source;

  /// Whether file should be cached or not
  final bool shouldCache;

  /// if this is set to true then file fetched from cached will get returned
  /// immediately and metadata comparison will happen in background.
  ///
  /// Otherwise metadata comparison is done first then the updated file will
  /// get returned.
  ///
  /// Note: Only applicable if source is set to source.cacheServerByMetadata
  final bool metadataRefreshInBackground;
}

/// The source from which file gets fetched
enum Source {
  /// Directly fetch file from server not from cache
  ///
  /// Note: file will still get cached.
  server,

  /// First try to fetch file from cache then try to fetch from server if
  /// file does not exist in cache.
  ///
  /// This is default 
  cacheServer,

  /// First try to fetch file from cache then if file does not exist then file
  /// will get fetched from server
  ///
  /// but if file does exist then it will compare the metadata of the file to the
  /// file in server if server has updated file then it will fetch file from server
  /// otherwise return file from cache.
  ///
  /// you can control whether metadata comparison happen in background or not by using
  /// [CacheOptions.metadataRefreshInBackground] flag
  cacheServerByMetadata,
}
```

Note: Metadata retrieval is a Class B operation in google cloud storage. you will be charged for that. Check pricing here (https://cloud.google.com/storage/pricing#price-tables).Google does offer 50,000 free Class B operations per month.


#### Web is supported without caching

Inspired From https://pub.dev/packages/firebase_image