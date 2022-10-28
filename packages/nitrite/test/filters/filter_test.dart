import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';
import 'package:test/test.dart';

void main() {
  group("Filters Test Suite", () {
    test("Test \$", () {
      expect($.runtimeType, FluentFilter);
      expect(($.eq(2) as EqualsFilter).field, "\$");
    });

    test("Test All", () {
      expect(all.runtimeType.toString(), '_All');
      expect(all.apply(emptyDocument()), isTrue);
    });

    test("Test Where", () {
      var clause = where('a');
      var filter = clause.eq(2);

      expect(clause, isNotNull);
      expect(clause.runtimeType, FluentFilter);
      expect(filter.runtimeType, EqualsFilter);

      expect((filter as EqualsFilter).field, 'a');
    });

    test("Test ById", () {
      var filter = byId(NitriteId.createId('1'));
      expect(filter.runtimeType, EqualsFilter);
      expect((filter as EqualsFilter).field, docId);
      expect((filter).value, '1');
    });

    test("Test CreateUniqueFilter", () {
      var doc = emptyDocument();
      var filter = createUniqueFilter(doc);
      expect(filter.runtimeType, EqualsFilter);
      expect((filter as EqualsFilter).field, docId);
      expect((filter).value, isA<String>());
    });
  });
}