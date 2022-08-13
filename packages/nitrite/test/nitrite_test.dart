import 'package:nitrite/src/store/memory/in_memory_meta_update.dart';
import 'package:test/test.dart';

void main() {
  MetaUpdate("pubspec.yaml")
      .writeMetaDartFile("lib/src/store/memory/in_memory_meta.dart");

  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Meta Check', () {
      MetaUpdate("pubspec.yaml").verifyLatestVersionFromPubSpec();
    });
  });
}
