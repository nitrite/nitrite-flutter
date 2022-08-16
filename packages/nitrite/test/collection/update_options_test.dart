import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

main() {
  group("Update Options Test Suite", () {
    setUp(() {});

    test("Test UpdateOptions", () {
      var options = UpdateOptions(insertIfAbsent: true, justOnce: true);
      expect(options.insertIfAbsent, isTrue);
      expect(options.justOnce, isTrue);
    });
  });
}
