import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

/// Mirrors the nitrite-java regressions for issues #1261 and #1262:
///
/// - an index range scan must not return an empty (or null-polluted) result
///   when the indexed field is null in some documents;
/// - sorting by a field that is null in more than one document must produce
///   a stable order (two null keys compare equal).
void main() {
  group('Index null key scan test', () {
    late Nitrite db;
    late NitriteCollection collection;

    setUp(() async {
      db = await Nitrite.builder().openOrCreate();
      collection = await db.getCollection('test');

      await collection.insert(emptyDocument().put('idx', 0).put('value', null));
      for (var i = 1; i <= 10; i++) {
        await collection.insert(
          emptyDocument().put('idx', i).put('value', i.toDouble()),
        );
      }
    });

    tearDown(() async {
      if (!db.isClosed) {
        await db.close();
      }
    });

    Future<void> checkRangeScans() async {
      expect(await collection.find(filter: where('value').lt(5.0)).length, 4);
      expect(await collection.find(filter: where('value').lte(5.0)).length, 5);
      expect(await collection.find(filter: where('value').gt(5.0)).length, 5);
      expect(await collection.find(filter: where('value').gte(5.0)).length, 6);

      // descending sort on the indexed field drives the reverse index scan
      var descending = await collection
          .find(
            filter: where('value').lt(5.0),
            findOptions: orderBy('value', SortOrder.descending),
          )
          .toList();
      expect(descending.length, 4);
      for (var doc in descending) {
        expect(doc['value'], isNotNull,
            reason: 'null-valued document leaked into lt result');
      }
    }

    test('range scans with nulls on non-unique index', () async {
      await collection.createIndex(['value'],
          indexOptions(IndexType.nonUnique));
      await checkRangeScans();
    });

    test('range scans with nulls on unique index', () async {
      await collection.createIndex(['value'], indexOptions(IndexType.unique));
      await checkRangeScans();
    });

    test('range scans with nulls without index', () async {
      await checkRangeScans();
    });

    test('in filter uses index and returns correct results', () async {
      await collection.createIndex(['value'],
          indexOptions(IndexType.nonUnique));
      expect(
        await collection
            .find(filter: where('value').within([1.0, 4.0, 7.0, 100.0]))
            .length,
        3,
      );
    });

    test('order by field with multiple nulls is stable', () async {
      var another = await db.getCollection('sortTest');
      for (var i = 0; i < 35; i++) {
        var doc = emptyDocument().put('idx', i);
        if (i % 3 != 0) {
          doc.put('value', i.toDouble());
        }
        await another.insert(doc);
      }

      var ascending = await another
          .find(findOptions: orderBy('value', SortOrder.ascending))
          .toList();
      expect(ascending.length, 35);

      // nulls must group first, then values in ascending order
      var nonNullSeen = false;
      double? previous;
      for (var doc in ascending) {
        var value = doc['value'] as double?;
        if (value == null) {
          expect(nonNullSeen, isFalse,
              reason: 'null found after non-null value in ascending sort');
        } else {
          nonNullSeen = true;
          if (previous != null) {
            expect(value, greaterThanOrEqualTo(previous));
          }
          previous = value;
        }
      }
    });
  });
}
