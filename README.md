# Firebase_Cached_Image

Cache Manager and Cached ImageProvider for Firebase Cloud Storage Objects.

## Set up

Setup firebase (https://firebase.google.com/docs/flutter/setup).

## Firebase Image Provider

If you want to show image from your cloud storage then use `Image` Widget and pass `FirebaseImageProvider` as `ImageProvider` to image argument. In `FirebaseImageProvider` pass `FirebaseUrl`.
`FirebaseUrl` is a class containing Google Storage Url String ex. `FirebaseUrl(gs://bucket_f233/logo.jpg)`.

```dart
Image(
  image: FirebaseImageProvider(
    FirebaseUrl("gs://bucket_f233/logo.jpg")
  ),
),
```

You can declare `FirebaseUrl` in following ways:

```dart
FirebaseUrl("gs://bucket_f233/logo.jpg")
FirebaseUrl("https://firebasestorage.googleapis.com/b/bucket/o/logo.jpg")
FirebaseUrl.fromReference(FirebaseStorage.instance.ref("images/image.jpg"));
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
    errorBuilder: (context, error, stackTrace) {
      // [ImageNotFoundException] will be thrown if image does not exist on server.
      if (error is ImageNotFoundException) {
        // Handle ImageNotFoundException and show a user-friendly message.
        return const Text('Image not found on Cloud Storage.');
      } else {
        // Handle other errors.
        return Text('Error loading image: $error');
      }
    },
    // The loading progress may not be accurate as Firebase Storage API
    // does not provide a stream of bytes downloaded. The progress updates only at the start and end of the loading process.
    loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
      if (loadingProgress == null) {
        // Show the loaded image if loading is complete.
        return child;
      } else {
        // Show a loading indicator with progress information.
        return CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  (loadingProgress.expectedTotalBytes ?? 1)
              : null,
        );
      }
    },
  ),
),
```

By default it will first try to fetch the image from cache, if image exists then it will be returned otherwise image will be fetched from server and then cached.

If you want to always fetch latest image from server then pass `Source.server` to `CacheOptions.source`.

```dart
  source: Source.server,
```

If you want to fetch image from server only if it is updated after last fetched then set `checkForMetadataChange` to `false`.

```dart
  checkForMetadataChange: true,
```

Image updation is checked by fetching image's metadata (modified timestamp) from server then comparing to cached image's metadata (modified timestamp).

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
  FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
)
```

Refresh already cached file..

Checks if the file has been updated in server, then download the file if it has been updated and saves it to cache.

```dart
await FirebaseCacheManager().refreshCachedFile(
  FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
);
```

Delete specific file from cache.

```dart
await FirebaseCacheManager().delete(
  FirebaseUrl("gs://bucket_f233/logo.jpg"),
);
```

Clear all the cache.

```dart
await FirebaseCacheManager().clearCache();
```

Use custom sub-directory to save files in desired directory in system's temporary directory. Default is "flutter_cached_image"

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
