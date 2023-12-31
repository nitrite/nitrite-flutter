import 'dart:collection';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'filter_test.mocks.dart';

@GenerateMocks([NitriteConfig, NitriteMapper])
void main() {
  group(retry: 3, "Filters Test Suite", () {
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

    test("Test And Filter", () {
      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', 2);

      var filter1 = and([where('a').eq(1), where('b').gt(1)]);
      expect(filter1.apply(doc), isTrue);

      var filter2 = and([where('a').eq(1), where('b').lt(1)]);
      expect(filter2.apply(doc), isFalse);

      var andFilter = filter1 as AndFilter;
      expect(andFilter.filters.length, 2);

      expect(() => and([]), throwsValidationException);
      expect(() => and([where('a').eq(1)]), throwsFilterException);
      expect(() => and([where('a').eq(1), where('b').text('b')]),
          throwsFilterException);

      expect(filter1.toString(), '((a == 1) && (b > 1))');
    });

    test("Test Or Filter", () {
      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', 2);

      var filter1 = or([where('a').eq(1), where('b').gt(1)]);
      expect(filter1.apply(doc), isTrue);

      filter1 = or([where('a').lt(1), where('b').gt(1)]);
      expect(filter1.apply(doc), isTrue);

      var filter2 = or([where('a').eq(1), where('b').lt(1)]);
      expect(filter2.apply(doc), isTrue);

      filter2 = or([where('a').lt(1), where('b').gt(10)]);
      expect(filter2.apply(doc), isFalse);

      var orFilter = filter1 as OrFilter;
      expect(orFilter.filters.length, 2);

      expect(() => or([]), throwsValidationException);
      expect(() => or([where('a').eq(1)]), throwsFilterException);

      expect(filter1.toString(), '((a < 1) || (b > 1))');
    });

    test("Test FluentFilter", () {
      var a = where('a');
      var b = where('b');
      var c = where('c');
      var d = where('d');

      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', '2');
      doc.put('d', [1, 2, 3]);

      expect(a.eq(1).apply(doc), isTrue);
      expect(c.eq(null).apply(doc), isTrue);
      expect(a.notEq(1).apply(doc), isFalse);
      expect(a.notEq(null).apply(doc), isTrue);
      expect(a.gt(0).apply(doc), isTrue);
      expect((a > 0).apply(doc), isTrue);
      expect(('a' > 0).apply(doc), isTrue);
      expect(a.gte(1).apply(doc), isTrue);
      expect((a >= 1).apply(doc), isTrue);
      expect(('a' >= 1).apply(doc), isTrue);
      expect(a.lt(2).apply(doc), isTrue);
      expect((a < 2).apply(doc), isTrue);
      expect(('a' < 2).apply(doc), isTrue);
      expect(a.lte(1).apply(doc), isTrue);
      expect((a <= 1).apply(doc), isTrue);
      expect(('a' <= 1).apply(doc), isTrue);
      expect(a.between(0, 2).apply(doc), isTrue);
      expect(b.text('2').apply(doc), isTrue);
      expect(b.regex(r'^[0-9]+').apply(doc), isTrue);
      expect(a.within([0, 1, 2]).apply(doc), isTrue);
      expect(a.notIn([10, 11, 12]).apply(doc), isTrue);
      expect(d.elemMatch($.lt(4)).apply(doc), isTrue);
      expect(d.elemMatch($.lt(3)).apply(doc), isTrue);
    });

    test("Test ~ Filter", () {
      var a = where('a');
      var b = where('b');

      var doc = emptyDocument();
      doc.put('a', 1);

      var filter = a.eq(1);
      var notFilter = ~filter;

      expect(filter.apply(doc), isTrue);
      expect(notFilter.apply(doc), isFalse);

      filter = b.eq(null);
      notFilter = ~filter;

      expect(filter.apply(doc), isTrue);
      expect(notFilter.apply(doc), isFalse);
    });
  });

  group(retry: 3, "NitriteFilter Test Suite", () {
    test("Test And", () {
      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', 2);
      doc.put('c', 3);

      var f1 = where('a').eq(1);
      var f2 = where('b').gt(1);
      var f3 = where('c').lt(4);

      var filter = f1.and(f2.and(f3));
      var filter2 = and([f1, f2, f3]);

      expect(
          filter,
          and([
            f1,
            and([f2, f3])
          ]));
      expect(filter.apply(doc), isTrue);
      expect(filter2.apply(doc), isTrue);
      expect((~filter).apply(doc), isFalse);
      expect((~filter2).apply(doc), isFalse);
    });

    test("Test Or", () {
      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', 2);
      doc.put('c', 3);

      var f1 = where('a').eq(1);
      var f2 = where('b').gt(1);
      var f3 = where('c').lt(4);

      var filter = f1.or(f2.or(f3));
      var filter2 = or([f1, f2, f3]);

      expect(
          filter,
          or([
            f1,
            or([f2, f3])
          ]));
      expect(filter.apply(doc), isTrue);
      expect(filter2.apply(doc), isTrue);
      expect((~filter).apply(doc), isFalse);
      expect((~filter2).apply(doc), isFalse);
    });

    test("Test & Operator", () {
      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', 2);
      doc.put('c', 3);

      var f1 = where('a').eq(1);
      var f2 = where('b').gt(1);
      var f3 = where('c').lt(4);

      var filter = f1 & (f2 & f3);
      var filter2 = and([f1, f2, f3]);

      expect(
          filter,
          and([
            f1,
            and([f2, f3])
          ]));
      expect(filter.apply(doc), isTrue);
      expect(filter2.apply(doc), isTrue);
      expect((~filter).apply(doc), isFalse);
      expect((~filter2).apply(doc), isFalse);

      expect((f1 & (('b' > 1) & ('c' < 4))).apply(doc), isTrue);
    });

    test("Test | Operator", () {
      var doc = emptyDocument();
      doc.put('a', 1);
      doc.put('b', 2);
      doc.put('c', 3);

      var f1 = where('a').eq(1);
      var f2 = where('b').gt(1);
      var f3 = where('c').lt(4);

      var filter = f1 | (f2 | f3);
      var filter2 = or([f1, f2, f3]);

      expect(
          filter,
          or([
            f1,
            or([f2, f3])
          ]));
      expect(filter.apply(doc), isTrue);
      expect(filter2.apply(doc), isTrue);
      expect((~filter).apply(doc), isFalse);
      expect((~filter2).apply(doc), isFalse);

      expect((f1 | (('b' > 1) | ('c' < 4))).apply(doc), isTrue);
    });
  });

  group(retry: 3, "FieldBasedFilter Test Suite", () {
    test("Test Value Accessor", () {
      var regex = where('a').regex(r'[0-9]+');

      expect(regex is FieldBasedFilter, isTrue);

      var config = MockNitriteConfig();
      var nitriteMapper = MockNitriteMapper();
      when(config.nitriteMapper).thenReturn(nitriteMapper);
      when(nitriteMapper.tryConvert<dynamic, Comparable>(any))
          .thenAnswer((invocation) => invocation.positionalArguments.first);

      regex.objectFilter = true;
      regex.nitriteConfig = config;

      expect((regex as FieldBasedFilter).value, r'[0-9]+');
      verify(nitriteMapper.tryConvert<dynamic, Comparable>(any)).called(1);

      var filter = where('').eq('') as FieldBasedFilter;
      filter.objectFilter = true;
      filter.nitriteConfig = config;
      expect(() => filter.value, throwsValidationException);
    });

    test("Test Invalid Field", () {
      var config = MockNitriteConfig();
      var nitriteMapper = MockNitriteMapper();
      when(config.nitriteMapper).thenReturn(nitriteMapper);
      when(nitriteMapper.tryConvert<dynamic, Comparable>(any))
          .thenAnswer((invocation) => invocation.positionalArguments.first);

      var filter = where('').eq('') as FieldBasedFilter;
      filter.objectFilter = true;
      filter.nitriteConfig = config;
      expect(() => filter.value, throwsValidationException);

      verifyNever(nitriteMapper.tryConvert<dynamic, Comparable>(any)).called(0);
    });
  });

  group(retry: 3, "ComparableFilter Test Suite", () {
    test("Test Comparable Accessor", () {
      var filter = where('a').gt(2) as ComparableFilter;
      expect(filter.comparable, 2);

      filter = where('a').gte(null) as ComparableFilter;
      expect(() => filter.comparable, throwsFilterException);

      filter = where('a').gte(filter.runtimeType) as ComparableFilter;
      expect(() => filter.comparable, throwsA(isA<TypeError>()));
    });

    test("Test YieldValues", () async {
      var filter = where('a').gt(2) as ComparableFilter;

      var stream = filter.yieldValues([1, 2, 3]);
      expect(stream, emitsInOrder([1, 2, 3]));

      var splayTreeMap = SplayTreeMap.from({});
      stream = filter.yieldValues(splayTreeMap);
      expect(stream, emitsInOrder([splayTreeMap]));
    });
  });

  group(retry: 3, "StringFilter Test Suite", () {
    test("Test StringValue Accessor", () {
      var filter = where('a').text('a') as StringFilter;

      expect(filter.stringValue, 'a');
    });
  });

  group(retry: 3, "ComparableArrayFilter Test Suite", () {
    test("Test ValidateSearchTerm", () {
      var filter = where('a').within([1, 2, 3]) as ComparableArrayFilter;

      var config = MockNitriteConfig();
      var nitriteMapper = MockNitriteMapper();
      when(config.nitriteMapper).thenReturn(nitriteMapper);
      when(nitriteMapper.tryConvert<dynamic, Comparable>(any))
          .thenAnswer((invocation) => invocation.positionalArguments.first);

      filter.objectFilter = true;
      filter.nitriteConfig = config;

      expect(filter.value, [1, 2, 3]);
      verifyNever(nitriteMapper.tryConvert<dynamic, Comparable>(any)).called(0);

      filter = where('').within([1, 2, 3]) as ComparableArrayFilter;
      filter.objectFilter = true;
      filter.nitriteConfig = config;
      expect(() => filter.value, throwsValidationException);
    });
  });

  group(retry: 3, "String Extension Test Suite", () {
    test("Test String Extensions - eq", () {
      var doc = emptyDocument();
      doc.put('a', 1);

      var f1 = 'a'.eq(1);
      var f2 = 'b'.eq(null);

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isTrue);
    });

    test("Test String Extensions - notEq", () {
      var doc = emptyDocument();
      doc.put('a', 1);

      var f1 = 'a'.notEq(2);
      var f2 = 'b'.notEq(null);

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isFalse);
    });

    test("Test String Extensions - gt", () {
      var doc = emptyDocument();
      doc.put('a', 2);

      var f1 = 'a'.gt(1);
      var f2 = 'b'.gt(null);
      var f3 = 'a'.gt(null);

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isFalse);
      expect(() => f3.apply(doc), throwsFilterException);
    });

    test("Test String Extensions - gte", () {
      var doc = emptyDocument();
      doc.put('a', 2);

      var f1 = 'a'.gte(1);
      var f2 = 'b'.gte(null);
      var f3 = 'a'.gte(null);

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isFalse);
      expect(() => f3.apply(doc), throwsFilterException);
    });

    test("Test String Extensions - lt", () {
      var doc = emptyDocument();
      doc.put('a', 0);

      var f1 = 'a'.lt(1);
      var f2 = 'b'.lt(null);
      var f3 = 'a'.lt(null);

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isFalse);
      expect(() => f3.apply(doc), throwsFilterException);
    });

    test("Test String Extensions - lte", () {
      var doc = emptyDocument();
      doc.put('a', 1);

      var f1 = 'a'.lte(1);
      var f2 = 'b'.lte(null);
      var f3 = 'a'.lte(null);

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isFalse);
      expect(() => f3.apply(doc), throwsFilterException);
    });

    test("Test String Extensions - between", () {
      var doc = emptyDocument();
      doc.put('a', 1);

      var f1 = 'a'.between(0, 2);

      expect(f1.apply(doc), isTrue);
    });

    test("Test String Extensions - within", () {
      var doc = emptyDocument();
      doc.put('a', 1);

      var f1 = 'a'.within([0, 1, 2]);

      expect(f1.apply(doc), isTrue);
    });

    test("Test String Extensions - notIn", () {
      var doc = emptyDocument();
      doc.put('a', 4);

      var f1 = 'a'.notIn([0, 1, 2]);

      expect(f1.apply(doc), isTrue);
    });

    test("Test String Extensions - elemMatch", () {
      var doc = emptyDocument();
      doc.put('a', [1, 3, 4]);

      var f1 = 'a'.elemMatch($.between(0, 5));

      expect(f1.apply(doc), isTrue);
    });

    test("Test String Extensions - text", () {
      var doc = emptyDocument();
      doc.put('a', "quick brown fox");

      var f1 = 'a'.text("*own");
      var f2 = 'a'.text("fo*");
      var f3 = 'a'.text("ump*");

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isTrue);
      expect(f3.apply(doc), isFalse);
    });

    test("Test String Extensions - regex", () {
      var doc = emptyDocument();
      doc.put('a', "quick brown fox");

      var f1 = 'a'.regex(r'[a-z]+');
      var f2 = 'a'.text('r[A-Z]+');
      var f3 = 'a'.text('r[0-9]+');

      expect(f1.apply(doc), isTrue);
      expect(f2.apply(doc), isFalse);
      expect(f3.apply(doc), isFalse);
    });
  });
}
