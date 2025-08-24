import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_cached_image/src/core/cached_object.dart';
import 'package:firebase_cached_image/src/firebase_cache_manager/base_firebase_cache_manager.dart';
import 'package:web/web.dart' as web;

class WebDbCacheManager {
  final Future<web.IDBDatabase> _db;

  WebDbCacheManager() : _db = _init();

  static Future<web.IDBDatabase> _init() {
    final complete = Completer<web.IDBDatabase>();

    final req = web.window.indexedDB.open(kDefaultImageCacheDir, 1);

    req.onerror = ((web.Event event) {
      final error = Exception("Database error: ${event.target}");

      complete.completeError(error);
    }).toJS;

    req.onsuccess = (web.Event event) {
      final db = (event.target as dynamic).result as web.IDBDatabase;

      complete.complete(db);
    }.toJS;

    req.onupgradeneeded = ((web.Event event) {
      final db = (event.target as dynamic)?.result as web.IDBDatabase;

      final store = db.createObjectStore(
        kDefaultImageCacheDir,
        web.IDBObjectStoreParameters(keyPath: "id".toJS),
      );

      store.createIndex(
        "subDir",
        "subDir".toJS,
        web.IDBIndexParameters(unique: false),
      );

      store.transaction.oncomplete = ((web.Event event) {}).toJS;
    }).toJS;

    return complete.future;
  }

  // TODO: Find a better way to check if exists
  Future<bool> exists(String id) async {
    final obj = await get(id);

    return obj != null && obj.rawData != null;
  }

  Future<CachedObject?> get(String id) async {
    final complete = Completer<CachedObject?>();

    final db = await _db;

    final store = db
        .transaction(kDefaultImageCacheDir.toJS, "readonly")
        .objectStore(kDefaultImageCacheDir);

    final req = store.get(id.toJS);

    req.onerror = ((web.Event event) {
      final error = Exception("Failed to get object: ${event.target}");

      complete.completeError(error);
    }).toJS;

    req.onsuccess = (web.Event event) {
      final result = (event.target as dynamic).result;

      if (result == null) {
        complete.complete(null);
      } else {
        CachedObject? data;

        if (result is Map) {
          data = CachedObject.fromMap(result.cast());
        } else {
          // WARN: Not sure about this case
          data = CachedObject.fromMap(
              ((result as JSObject).dartify()! as Map).cast());
        }

        if (data.rawData == null) {
          return complete.complete(null);
        }

        complete.complete(data);
      }
    }.toJS;

    return complete.future;
  }

  Future<void> put(CachedObject object, {String? subDir}) async {
    final db = await _db;

    final complete = Completer<void>();

    final store = db
        .transaction(kDefaultImageCacheDir.toJS, "readwrite")
        .objectStore(kDefaultImageCacheDir);

    final data = object.toMap();

    data["subDir"] = subDir ?? kDefaultImageCacheDir;

    final req = store.put(data.jsify());

    req.onerror = ((web.Event event) {
      final error = Exception("Failed to put object: ${event.target}");

      complete.completeError(error);
    }).toJS;

    req.onsuccess = (web.Event event) {
      complete.complete();
    }.toJS;
  }

  Future<void> delete(String id) async {
    final db = await _db;

    final complete = Completer<void>();

    final store = db
        .transaction(kDefaultImageCacheDir.toJS, "readwrite")
        .objectStore(kDefaultImageCacheDir);

    final req = store.delete(id.toJS);

    req.onerror = ((web.Event event) {
      final error = Exception("Failed to delete object: ${event.target}");

      complete.completeError(error);
    }).toJS;

    req.onsuccess = (web.Event event) {
      complete.complete();
    }.toJS;
  }

  Future<void> clear({
    String? subDir,
  }) async {
    final complete = Completer<void>();

    final db = await _db;

    final txn = db.transaction(kDefaultImageCacheDir.toJS, "readwrite");
    final store = txn.objectStore(kDefaultImageCacheDir);

    final index = store.index("subDir");

    index.delete((subDir ?? kDefaultImageCacheDir).toJS);

    txn.onerror = ((web.Event event) {
      final error = Exception("Failed to clear objects: ${event.target}");

      complete.completeError(error);
    }).toJS;

    txn.oncomplete = (web.Event event) {
      complete.complete();
    }.toJS;

    return complete.future;
  }
}
