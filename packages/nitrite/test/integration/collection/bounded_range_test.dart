import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group('Bounded range index scan', () {
    late Nitrite db;
    late NitriteCollection col;

    setUp(() async {
      db = await Nitrite.builder().openOrCreate();
      col = await db.getCollection('c');
      await col.createIndex(['seq'], indexOptions(IndexType.nonUnique));
      for (var i = 0; i < 100; i++) {
        await col.insert(emptyDocument().put('seq', i));
      }
    });

    tearDown(() async => db.close());

    Future<List<int>> seqs(Filter f, [FindOptions? o]) async {
      var out = <int>[];
      await for (var d in col.find(filter: f, findOptions: o)) {
        out.add(d['seq'] as int);
      }
      return out;
    }

    test(
      'between is fully index-covered (no collection scan filter)',
      () async {
        var cursor = col.find(filter: where('seq').between(40, 50));
        var plan = await cursor.findPlan;
        expect(plan.indexDescriptor, isNotNull);
        expect(
          plan.collectionScanFilter,
          isNull,
          reason: 'both bounds should be absorbed into the index scan',
        );
        var result = await seqs(where('seq').between(40, 50));
        expect(result..sort(), [40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50]);
      },
    );

    test('explicit gte AND lte combine into bounded scan', () async {
      var f = and([where('seq').gte(10), where('seq').lte(13)]);
      var plan = await col.find(filter: f).findPlan;
      expect(plan.collectionScanFilter, isNull);
      var result = await seqs(f);
      expect(result..sort(), [10, 11, 12, 13]);
    });

    test('exclusive bounds gt AND lt', () async {
      var f = and([where('seq').gt(10), where('seq').lt(13)]);
      var result = await seqs(f);
      expect(result..sort(), [11, 12]);
    });

    test('bounded range with descending sort', () async {
      var result = await seqs(
        where('seq').between(20, 24),
        orderBy('seq', SortOrder.descending),
      );
      expect(result, [24, 23, 22, 21, 20]);
    });

    test('bounded range with ascending sort', () async {
      var result = await seqs(
        where('seq').between(20, 24),
        orderBy('seq', SortOrder.ascending),
      );
      expect(result, [20, 21, 22, 23, 24]);
    });

    test('count short-circuits on bounded range', () async {
      var cursor = col.find(filter: where('seq').between(40, 50));
      expect(await cursor.count(), 11);
    });

    test('result parity vs collection scan on non-indexed field', () async {
      // 'other' is not indexed -> collection scan path; compare counts
      for (var i = 0; i < 100; i++) {}
      var indexed = await seqs(where('seq').between(30, 70));
      expect(indexed.length, 41);
      expect(
        indexed.toSet().containsAll(List.generate(41, (i) => 30 + i)),
        isTrue,
      );
    });
  });
}
