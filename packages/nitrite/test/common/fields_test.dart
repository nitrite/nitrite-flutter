import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group('Fields Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Constructor', () {
      var fields = Fields();
      expect(fields.toString(), "[]");
    });

    test('Constructor with names', () {
      var fields = Fields.withNames(["name", "age"]);
      expect(fields.toString(), "[name, age]");
    });

    test('Add field', () {
      var fields = Fields();
      fields.addField("name");
      expect(fields.toString(), "[name]");
    });

    test('Add fields', () {
      var fields = Fields();
      fields.addField("name");
      fields.addField("age");
      expect(fields.toString(), "[name, age]");
    });

    test("Get Fields Name", () {
      var fields = Fields();
      expect(fields.fieldNames, isEmpty);
    });

    test("Starts With", () {
      var fields = Fields.withNames(["name", "age"]);
      var otherFields = Fields.withNames(["name", "age", "sex"]);
      expect(fields.startWith(otherFields), isFalse);
      expect(otherFields.startWith(fields), isTrue);
    });

    test("Encode Names", () {
      var fields = Fields.withNames(["name", "age"]);
      expect(fields.encodedName, "name|age");

      fields = Fields.withNames(["name", "age", "sex"]);
      expect(fields.encodedName, "name|age|sex");
    });

    test("Compare To", () {
      var fields = Fields.withNames(["name", "age"]);
      expect(fields.compareTo(Fields()), 1);

      expect(fields.compareTo(Fields.withNames(["name", "age"])), 0);
    });
  });
}
