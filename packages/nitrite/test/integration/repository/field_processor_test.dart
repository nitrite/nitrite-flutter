import 'package:test/scaffolding.dart';

import 'base_object_repository_test_loader.dart';

void main() {
  group('Field Processor Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });
  });
}
