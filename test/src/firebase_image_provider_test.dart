import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'cloud_storage_manager/cloud_storage_manager_test.mocks.dart';

void main() {
  test('two providers are equal with same params', () {
    final MockReference ref = MockReference();
    when(ref.fullPath).thenReturn("userIcon123");
    when(ref.bucket).thenReturn("bucket123");
    final url = FirebaseUrl.fromReference(ref);
    final fallbackUrl = FirebaseUrl.fromReference(ref);

    final provider = FirebaseImageProvider(
      url,
      fallbackUrl: fallbackUrl,
      subDir: "flutter_cached_image",
    );

    final provider2 = FirebaseImageProvider(
      url,
      fallbackUrl: fallbackUrl,
      subDir: "flutter_cached_image",
    );

    expect(provider, provider2);
  });
}
