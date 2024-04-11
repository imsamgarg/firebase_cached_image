import 'dart:typed_data';

import 'package:firebase_cached_image/src/cloud_storage_manager/cloud_storage_manager.dart';
import 'package:firebase_cached_image/src/core/firebase_url.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'cloud_storage_manager_test.mocks.dart';

@GenerateMocks([FirebaseUrl, FullMetadata, Reference])
void main() {
  final mockFirebaseUrl = MockFirebaseUrl();
  final mockMetadata = MockFullMetadata();
  final cloudStorageManager = CloudStorageManager();
  final mockRef = MockReference();

  setUpAll(() {
    when(mockFirebaseUrl.ref).thenReturn(mockRef);
  });

  test('downloadLatestFile returns correct data', () async {
    when(mockRef.getData(any))
        .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

    final result =
        await cloudStorageManager.downloadLatestFile(mockFirebaseUrl);

    expect(result, equals(Uint8List.fromList([1, 2, 3])));
  });

  test('isUpdated returns true when cloud file is newer', () async {
    when(mockRef.getMetadata()).thenAnswer((_) async => mockMetadata);
    final nowDate = DateTime.now();
    when(mockMetadata.updated).thenReturn(nowDate);

    final result = await cloudStorageManager.isUpdated(
      mockFirebaseUrl,
      nowDate.millisecondsSinceEpoch - 1000,
    );

    expect(result, equals(true));
  });

  test('isUpdated returns false when cloud file is older', () async {
    when(mockRef.getMetadata()).thenAnswer((_) async => mockMetadata);

    final nowDate = DateTime.now();
    when(mockMetadata.updated).thenReturn(nowDate);

    final result = await cloudStorageManager.isUpdated(
      mockFirebaseUrl,
      nowDate.millisecondsSinceEpoch + 1000,
    );

    expect(result, equals(false));
  });

  test('isUpdated returns false when cloud file is same', () async {
    when(mockRef.getMetadata()).thenAnswer((_) async => mockMetadata);

    final nowDate = DateTime.now();
    when(mockMetadata.updated).thenReturn(nowDate);

    final result = await cloudStorageManager.isUpdated(
      mockFirebaseUrl,
      nowDate.millisecondsSinceEpoch,
    );

    expect(result, equals(false));
  });
}
