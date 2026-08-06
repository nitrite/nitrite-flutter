import 'package:dbinspect_bridge/dbinspect_bridge.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_bridge/src/filter_dsl.dart';
import 'package:test/test.dart';

/// Every operator is checked by *applying* the filter to documents rather than
/// by asserting on the object it built. A mapping that compiles and selects the
/// wrong rows is the failure worth catching.
Document doc(Map<String, Object?> fields) {
  final document = emptyDocument();
  fields.forEach(document.put);
  return document;
}

Matcher selects(List<Document> documents, List<String> names) =>
    predicate<Filter>((filter) {
      final matched = [
        for (final document in documents)
          if (filter.apply(document)) document.get<String>('name')
      ];
      expect(matched, names);
      return true;
    }, 'selects $names');

void main() {
  final people = [
    doc({'name': 'ada', 'age': 36, 'city': 'london'}),
    doc({'name': 'bob', 'age': 20, 'city': 'paris'}),
    doc({'name': 'cyd', 'age': 55, 'city': 'london'}),
  ];

  Filter parse(Map<String, Object?> tree, {bool allowRegex = false}) =>
      parseFilter(tree, allowRegex: allowRegex);

  Matcher badRequest(String because) => throwsA(isA<BridgeException>()
      .having((e) => e.kind, 'kind', BridgeErrorKind.badRequest)
      .having((_) => because, 'because', because));

  group('every advertised operator round-trips', () {
    test('capabilities and the parser agree on the operator set', () {
      // `filterOps` is authoritative for the client, so an operator advertised
      // and not implemented is a greyed-out control that lies in the other
      // direction. Both lists are here so they cannot drift apart.
      for (final op in nitriteFilterOps) {
        expect(
          () => parse({'field': 'age', 'op': op, 'value': _sampleFor(op)}),
          returnsNormally,
          reason: 'filterOps advertises "$op"',
        );
      }
    });

    test('comparisons', () {
      expect(parse({'field': 'age', 'op': 'eq', 'value': 20}),
          selects(people, ['bob']));
      expect(parse({'field': 'age', 'op': 'ne', 'value': 20}),
          selects(people, ['ada', 'cyd']));
      expect(parse({'field': 'age', 'op': 'gt', 'value': 36}),
          selects(people, ['cyd']));
      expect(parse({'field': 'age', 'op': 'gte', 'value': 36}),
          selects(people, ['ada', 'cyd']));
      expect(parse({'field': 'age', 'op': 'lt', 'value': 36}),
          selects(people, ['bob']));
      expect(parse({'field': 'age', 'op': 'lte', 'value': 36}),
          selects(people, ['ada', 'bob']));
    });

    test('membership', () {
      expect(
          parse({
            'field': 'city',
            'op': 'in',
            'value': ['paris', 'berlin']
          }),
          selects(people, ['bob']));
      expect(
          parse({
            'field': 'city',
            'op': 'notIn',
            'value': ['paris']
          }),
          selects(people, ['ada', 'cyd']));
    });

    test('combinators, including the one-clause form the protocol sends', () {
      expect(
          parse({
            'and': [
              {'field': 'city', 'op': 'eq', 'value': 'london'},
              {'field': 'age', 'op': 'gt', 'value': 40},
            ]
          }),
          selects(people, ['cyd']));
      expect(
          parse({
            'or': [
              {'field': 'name', 'op': 'eq', 'value': 'ada'},
              {'field': 'name', 'op': 'eq', 'value': 'bob'},
            ]
          }),
          selects(people, ['ada', 'bob']));
      expect(
          parse({
            'not': {'field': 'city', 'op': 'eq', 'value': 'london'}
          }),
          selects(people, ['bob']));

      // `docs/PROTOCOL.md` §2's own queryPage example sends a single-element
      // `and`, and Nitrite's `and()` throws below two operands.
      expect(
          parse({
            'and': [
              {'field': 'age', 'op': 'gt', 'value': 30}
            ]
          }),
          selects(people, ['ada', 'cyd']));
    });
  });

  group('what this implementation does not have', () {
    test('exists is refused rather than mistranslated', () {
      // nitrite-flutter has no exists filter. PROTOCOL §1: an operator that is
      // out of scope must be absent from `filterOps`, never silently turned
      // into something else.
      expect(nitriteFilterOps, isNot(contains('exists')));
      expect(() => parse({'field': 'age', 'op': 'exists', 'value': true}),
          badRequest('there is no exists filter to map it onto'));
    });

    test('an unknown operator is a bad request, not an unfiltered page', () {
      expect(() => parse({'field': 'age', 'op': 'nearby', 'value': 1}),
          badRequest('the client sent something this bridge cannot honour'));
    });

    test('spatial, full-text-index and vector operators are simply absent', () {
      for (final op in ['near', 'within', 'intersects', 'knn']) {
        expect(() => parse({'field': 'geo', 'op': op, 'value': 1}),
            badRequest('out of scope for v1'));
      }
    });
  });

  group('the tree is untrusted input', () {
    test('a malformed node is refused', () {
      for (final tree in <Map<String, Object?>>[
        {},
        {'field': 'age'},
        {'op': 'eq', 'value': 1},
        {'field': '', 'op': 'eq', 'value': 1},
        {'field': 'age', 'op': 42, 'value': 1},
        {'and': <Object?>[]},
        {'and': 'nope'},
        {
          'or': [42]
        },
      ]) {
        expect(() => parse(tree), badRequest('malformed: $tree'));
      }
    });

    test('an unbounded nesting depth is refused before it is a stack frame',
        () {
      Map<String, Object?> tree = {'field': 'age', 'op': 'eq', 'value': 1};
      for (var i = 0; i <= maxFilterDepth; i++) {
        tree = {
          'and': [tree]
        };
      }
      expect(() => parse(tree), badRequest('deeper than $maxFilterDepth'));
    });

    test('an ordering comparison against a non-comparable is refused', () {
      // Otherwise it throws inside the engine, mid-page, with a message about
      // Nitrite internals.
      for (final op in ['gt', 'gte', 'lt', 'lte']) {
        expect(() => parse({'field': 'age', 'op': op, 'value': true}),
            badRequest('$op against a bool'));
        expect(
            () => parse({
                  'field': 'age',
                  'op': op,
                  'value': {'a': 1}
                }),
            badRequest('$op against an object'));
      }
    });

    test('membership needs a non-empty list of comparable values', () {
      for (final value in <Object?>[
        'paris',
        <Object?>[],
        [true],
        [
          {'a': 1}
        ],
      ]) {
        expect(() => parse({'field': 'city', 'op': 'in', 'value': value}),
            badRequest('in $value'));
      }
    });
  });

  group('regex is off unless the developer allowed it (criterion 9)', () {
    test('absent from the advertised operators', () {
      expect(nitriteFilterOps, isNot(contains('regex')));
    });

    test('refused with a badRequest when it was not allowed', () {
      expect(() => parse({'field': 'name', 'op': 'regex', 'value': 'a'}),
          badRequest('allowRegex is off'));
    });

    test('accepted and applied when it was', () {
      expect(
          parse({'field': 'name', 'op': 'regex', 'value': '^a'},
              allowRegex: true),
          selects(people, ['ada']));
    });

    test('the nested-quantifier pattern returns instead of hanging', () {
      // Criterion 9's second half. A Dart RegExp match cannot be interrupted
      // once it starts, so the only way to bound `(a+)+$` is to never start it.
      final stopwatch = Stopwatch()..start();
      expect(
          () => parse({'field': 'name', 'op': 'regex', 'value': r'(a+)+$'},
              allowRegex: true),
          badRequest('nested quantifier'));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('an over-long or invalid pattern is refused', () {
      expect(
          () => parse({
                'field': 'name',
                'op': 'regex',
                'value': 'a' * (maxRegexPatternLength + 1)
              }, allowRegex: true),
          badRequest('over the length cap'));
      expect(
          () => parse({'field': 'name', 'op': 'regex', 'value': '('},
              allowRegex: true),
          badRequest('not a valid pattern'));
    });
  });
}

Object _sampleFor(String op) => switch (op) {
      'in' || 'notIn' => [1],
      'text' => 'ada',
      _ => 1,
    };
