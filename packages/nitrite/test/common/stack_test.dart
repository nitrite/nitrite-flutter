import 'package:nitrite/src/common/stack.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group("Stack Test Suite", () {

    test("Test IsEmpty", () {
      var stack = Stack();
      expect(stack.isEmpty, isTrue);

      stack.push(DateTime.now());
      expect(stack.isEmpty, isFalse);

      stack.pop();
      expect(stack.isEmpty, isTrue);
    });

    test("Test IsNotEmpty", () {
      var stack = Stack();
      expect(stack.isNotEmpty, isFalse);

      stack.push(DateTime.now());
      expect(stack.isNotEmpty, isTrue);

      stack.pop();
      expect(stack.isNotEmpty, isFalse);
    });

    test("Test Push", () {
      var stack = Stack();
      expect(stack.size(), 0);

      stack.push(DateTime.now());
      expect(stack.size(), 1);

      stack.push("a");
      expect(stack.size(), 2);
    });

    test("Test Pop", () {
      var stack = Stack();
      expect(stack.size(), 0);

      stack.push(DateTime.now());
      stack.push("a");
      expect(stack.size(), 2);

      stack.pop();
      expect(stack.size(), 1);

      stack.pop();
      expect(stack.size(), 0);

      expect(() => stack.pop(), throwsInvalidOperationException);
    });

    test("Test Top", () {
      var stack = Stack();
      expect(() => stack.top(), throwsInvalidOperationException);

      stack.push(DateTime.now());
      stack.push("a");
      expect(stack.top(), "a");

      stack.pop();
      expect(stack.top(), isA<DateTime>());

      stack.pop();
      expect(stack.size(), 0);

      expect(() => stack.top(), throwsInvalidOperationException);
    });

    test("Test Size", () {
      var stack = Stack();
      expect(stack.size(), 0);

      stack.push(DateTime.now());
      stack.push("a");
      expect(stack.size(), 2);

      stack.pop();
      expect(stack.size(), 1);

      stack.pop();
      expect(stack.size(), 0);
    });

    test("Test Length", () {
      var stack = Stack();
      expect(stack.length, 0);

      stack.push(DateTime.now());
      stack.push("a");
      expect(stack.length, 2);

      stack.pop();
      expect(stack.length, 1);

      stack.pop();
      expect(stack.length, 0);
    });

    test("Test Contains", () {
      var stack = Stack();
      stack.push(DateTime.now());
      stack.push("a");

      expect(stack.contains("a"), isTrue);
      expect(stack.contains(DateTime.now()), isFalse); // date time value is different now
    });
  });
}