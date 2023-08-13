import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group(retry: 3, "Tuples Test Suite", () {
    test("Test Triplets", () {
      final triplet1 = Triplet(1, 2, 3);
      final triplet2 = Triplet(1, 2, 3);

      expect(triplet1.first, 1);
      expect(triplet1.second, 2);
      expect(triplet1.third, 3);
      expect(triplet1.first, triplet2.first);
      expect(triplet1.second, triplet2.second);
      expect(triplet1.third, triplet2.third);

      expect(triplet1, triplet2);
      expect(triplet1.hashCode, triplet2.hashCode);
      expect(triplet1.toString(), triplet2.toString());

      final triplet3 = Triplet(1, 2, 4);
      expect(triplet1, isNot(triplet3));
      expect(triplet1.hashCode, isNot(triplet3.hashCode));
      expect(triplet1.toString(), isNot(triplet3.toString()));

      final triplet4 = Triplet(1, null, 3);
      expect(triplet4.first, 1);
      expect(triplet4.second, isNull);
      expect(triplet4.third, 3);
      expect(triplet1, isNot(triplet4));
      expect(triplet1.hashCode, isNot(triplet4.hashCode));
      expect(triplet1.toString(), isNot(triplet4.toString()));
    });

    test("Test Quartets", () {
      final quartet1 = Quartet(1, 2, 3, 4);
      final quartet2 = Quartet(1, 2, 3, 4);

      expect(quartet1.first, 1);
      expect(quartet1.second, 2);
      expect(quartet1.third, 3);
      expect(quartet1.fourth, 4);
      expect(quartet1.first, quartet2.first);
      expect(quartet1.second, quartet2.second);
      expect(quartet1.third, quartet2.third);
      expect(quartet1.fourth, quartet2.fourth);

      expect(quartet1, quartet2);
      expect(quartet1.hashCode, quartet2.hashCode);
      expect(quartet1.toString(), quartet2.toString());

      final quartet3 = Quartet(1, 2, 3, 5);
      expect(quartet1, isNot(quartet3));
      expect(quartet1.hashCode, isNot(quartet3.hashCode));
      expect(quartet1.toString(), isNot(quartet3.toString()));

      final quartet4 = Quartet(1, null, 3, 4);
      expect(quartet4.first, 1);
      expect(quartet4.second, isNull);
      expect(quartet4.third, 3);
      expect(quartet4.fourth, 4);
      expect(quartet1, isNot(quartet4));
      expect(quartet1.hashCode, isNot(quartet4.hashCode));
      expect(quartet1.toString(), isNot(quartet4.toString()));
    });

    test("Test Quintets", () {
      final quintet1 = Quintet(1, 2, 3, 4, 5);
      final quintet2 = Quintet(1, 2, 3, 4, 5);

      expect(quintet1.first, 1);
      expect(quintet1.second, 2);
      expect(quintet1.third, 3);
      expect(quintet1.fourth, 4);
      expect(quintet1.fifth, 5);
      expect(quintet1.first, quintet2.first);
      expect(quintet1.second, quintet2.second);
      expect(quintet1.third, quintet2.third);
      expect(quintet1.fourth, quintet2.fourth);
      expect(quintet1.fifth, quintet2.fifth);

      expect(quintet1, quintet2);
      expect(quintet1.hashCode, quintet2.hashCode);
      expect(quintet1.toString(), quintet2.toString());

      final quintet3 = Quintet(1, 2, 3, 4, 6);
      expect(quintet1, isNot(quintet3));
      expect(quintet1.hashCode, isNot(quintet3.hashCode));
      expect(quintet1.toString(), isNot(quintet3.toString()));

      final quintet4 = Quintet(1, null, 3, 4, 5);
      expect(quintet4.first, 1);
      expect(quintet4.second, isNull);
      expect(quintet4.third, 3);
      expect(quintet4.fourth, 4);
      expect(quintet4.fifth, 5);
      expect(quintet1, isNot(quintet4));
      expect(quintet1.hashCode, isNot(quintet4.hashCode));
      expect(quintet1.toString(), isNot(quintet4.toString()));
    });
  });
}
