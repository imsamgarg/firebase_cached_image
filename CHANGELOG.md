## 0.5.0

- Implemented `ImageProvider.loadImage` method
- Fixed downloading image twice when the source is Source.server
- Do no cache file if the source is Source.server
- `FirebaseImageProvider` instance equality issue fixed
- CacheOptions.shouldCache field removed (breaking)
- CacheOptions.checkForMetadataChange is not false by default (breaking)
- Deprecated CacheOptions.metadataRefreshInBackground field (will remove this field in future)
- Added modifiedBefore arg in FirebaseCacheManager.clearCache method
- Added basic error handling in `FirebaseImageProvider`, Now you can check if the error is `ImageNotFoundException` in Image.errorBuilder callback to indicate file not found on the server.
- FirebaseUrl() constructor now support both firebase or google storage url
- Fixed `FirebaseCacheManager.clearCache` method not respecting the subDir field and clearing the entire cache

## 0.4.5

- fixed broken FirebaseCacheManager.delete() method ([#13](https://github.com/imsamgarg/firebase_cached_image/pull/13))

## 0.4.4

- Files will be saved with it's extensions
- Bug fixes

## 0.4.3

- FirebaseCacheManager.isCached method added
- Bug fixes

## 0.4.2

- added loadingBuilder support

## 0.4.1

- bug fixes

## 0.4.0

- Breaking Changes
- Singleton pattern removed
- shouldCache removed
- Bug fixes
- moved ref param to FirebaseUrl
- New methods added
- Dependencies fix

## 0.3.1

- readme updated

## 0.3.0

- Bug Fixes.
- Some Apis changed.
- Added more functionality

## 0.2.0

- database changed to sqflite.
- removed web support

## 0.1.0

- initial release.
