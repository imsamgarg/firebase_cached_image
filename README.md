# Firebase_Cached_Image

Cache Manager and Cached ImageProvider for Firebase Cloud Storage Objects.

## Set up

Setup firebase (https://firebase.google.com/docs/flutter/setup).

## Web Support

Web support is experimental. To enable it, add the following line in your main() function:

```dart
FirebaseCacheManagerConfig.webSupport = true;
```

On the web, It uses `indexed_db` for caching the files. All the files are directly saved to the browser's IndexedDB store. Read more about IndexedDB here (https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API).

# Usage

## Firebase Image Provider

To display an image from Firebase Cloud Storage, use FirebaseImageProvider as the ImageProvider for the Flutter Image widget.

```dart
Image(
  image: FirebaseImageProvider(
    FirebaseUrl("gs://bucket_f233/logo.jpg"),
    // Optional: Display this image if the main image not found on the server
    fallbackUrl: FirebaseUrl("gs://bucket/sad-image.jpg"),
  ),
),
```

You can declare `FirebaseUrl` in following ways:

```dart
FirebaseUrl("gs://bucket_f233/logo.jpg")
FirebaseUrl("https://firebasestorage.googleapis.com/b/bucket/o/logo.jpg")
FirebaseUrl.fromReference(FirebaseStorage.instance.ref("images/image.jpg"));
```

## Cache Options

Customize caching behavior with `CacheOptions`:

```dart
Image(
  image: FirebaseImageProvider(
    FirebaseUrl("gs://bucket_f233/logo.jpg"),
    options: CacheOptions(
      checkIfFileUpdatedOnServer: false,
      source: Source.cacheServer,
    ),
  ),
),
```

- **Default behavior**: Load from cache if available; otherwise fetch from server and then cache.  
- **Cache for specified duration**: Load from cache if not older than duration; otherwise fetch from server and update cache.
  ```dart
  cacheTime: Duration(days: 7),
  ```
- **Always fetch latest from server**:  
  ```dart
  source: Source.server,
  ```
- **Fetch from server only if updated since last fetch**:  
  ```dart
  checkIfFileUpdatedOnServer: true,
  ```

> **Note:** Image update checks require fetching metadata (last modified timestamp) from Firebase Storage.  
This is a **Class B operation** in Google Cloud Storage, which may incur charges after 50,000 free operations per month. [Pricing details](https://cloud.google.com/storage/pricing#price-tables).
---


## Firebase Cache Manager

For more control and support beyond images (e.g., docs, videos), use `FirebaseCacheManager`.

### Download and Cache a File

_Not supported on web._

```dart
final file = await FirebaseCacheManager().getSingleFile(
  FirebaseUrl("gs://bucket_f233/doc.docx"),
);
print(file); // Local cached file path (useful for sharing/reading)
```

You can also use `getSingleObject` method to get the file as bytes:

_Supported on web._

```dart
final cachedObject = await FirebaseCacheManager().getSingleObject(
  FirebaseUrl("gs://bucket_f233/doc.docx"),
);

print(cachedObject.rawBytes); // Uint8List of file bytes
```

### Pre-cache a File

Pre-download files you know will be needed soon (e.g., profile pictures at app start):

```dart
await FirebaseCacheManager().preCache(
  FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
);
```

### Refresh a Cached File

Update a cached file if it has changed on the server:

```dart
await FirebaseCacheManager().refreshCachedFile(
  FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
);
```

### Copy a Local File to Cache

Avoid re-downloading by copying an existing local file into the cache.  
_Not supported on web._

```dart
final filePath = "/storage/file.jpg";
final cachedFilePath = await FirebaseCacheManager().copyToCache(
  FirebaseUrl("gs://bucket_f233/profile_pic.jpg"),
  filePath,
);
```

### Delete a Cached File

```dart
await FirebaseCacheManager().delete(
  FirebaseUrl("gs://bucket_f233/logo.jpg"),
);
```

### Clear Cache

```dart
// Clear entire cache (Supported on web)
await FirebaseCacheManager().clearCache();

// Clear files older than 20 days (Not supported on web)
await FirebaseCacheManager().clearCache(modifiedBefore: Duration(days: 20));
```

### Custom Sub-Directory

Save cached files in a custom subdirectory inside the system’s temporary directory.  
_Default:_ `"flutter_cached_image"`

```dart
final manager = FirebaseCacheManager(subDir: "profile_pictures");
```

This allows organizing cached files by category:

```dart
final profilePicturesCacheManager = FirebaseCacheManager(subDir: "profile_pictures");
final postsCacheManager = FirebaseCacheManager(subDir: "posts");

// Clear only "posts" cache
await postsCacheManager.clearCache();
```

### Platform Support

| Method                       | Mobile       | Web              |
| ---------------------------- | ------------ | ---------------- |
| `getSingleFile()`            | ✅ Supported | ✅ Supported     |
| `preCache()`                 | ✅ Supported | ✅ Supported     |
| `refreshCachedFile()`        | ✅ Supported | ✅ Supported     |
| `copyToCache()`              | ✅ Supported | ❌ Not Supported |
| `delete()`                   | ✅ Supported | ✅ Supported     |
| `clearCache()` (all files)   | ✅ Supported | ✅ Supported     |
| `clearCache(modifiedBefore)` | ✅ Supported | ❌ Not Supported |
