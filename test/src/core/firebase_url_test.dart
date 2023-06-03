import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart';

import '../../helper_functions_test.mocks.dart';

void main() {
  test("valid parsing with extension", () {
    const String url = "gs://bucket123/userIcon123.jpg";
    const uid = "ee8f1f7f-b80d-5daa-848d-afa83a631922";

    final MockReference ref = MockReference();

    final ext = extension(url);
    when(ref.fullPath).thenReturn("userIcon123.jpg");
    when(ref.bucket).thenReturn("bucket123");

    final FirebaseUrl uri = FirebaseUrl.fromReference(ref);
    expect(extension(uri.uniqueId), ext);
    expect(uri.uniqueId, uid + ext);
    expect(Uri.parse(url), uri.url);
    expect(uri.ref, ref);
  });
  test("valid parsing without extension", () {
    const String url = "gs://bucket123/userIcon123";
    const uid = "7ae75d8a-0bda-5dd2-b120-b37986700372";

    final MockReference ref = MockReference();

    final ext = extension(url);
    when(ref.fullPath).thenReturn("userIcon123");
    when(ref.bucket).thenReturn("bucket123");

    final FirebaseUrl uri = FirebaseUrl.fromReference(ref);
    expect(extension(uri.uniqueId), ext);
    expect(uri.uniqueId, uid + ext);
    expect(Uri.parse(url), uri.url);
    expect(uri.ref, ref);
  });
}
