import 'package:nitrite/src/collection/snowflake_id.dart';
import 'package:test/test.dart';

main() {
  group("Snowflake Id Generator Test Suite", () {
    setUp(() {});

    test("Test Id", () {
      var generator = SnowflakeIdGenerator();
      expect(generator.id, isNonZero);
    });

    test("Test Uniqueness", () {
      var generator = SnowflakeIdGenerator();
      var ids = <int>[];
      for (var i = 0; i < 100; i++) {
        ids.add(generator.id);
      }

      // 100 unique ids should be generated.
      expect(ids.length, 100);
    });
  });
}