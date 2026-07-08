import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

/// Mirrors nitrite-java issue #1266: an AND filter combining an equality
/// filter on one indexed field with a bounded range (gte/lte) on a second,
/// differently-typed indexed field threw when the query planner picked
/// filters from more than one index into the same index scan.
void main() {
  group('Issue 1266 test', () {
    late Nitrite db;
    late NitriteCollection collection;

    setUp(() async {
      db = await Nitrite.builder().openOrCreate();
      collection = await db.getCollection('items');

      // a single-field index (matches exactly one field per candidate) next
      // to a compound index (matches two fields per candidate) - so the two
      // candidates the planner considers have different filter counts.
      await collection.createIndex(['name']);
      await collection.createIndex(['qty', 'qty2']);

      await collection.insert(
        emptyDocument()
            .put('name', 'item_c')
            .put('qty', 5)
            .put('qty2', 10),
      );
    });

    tearDown(() async {
      if (!db.isClosed) {
        await db.close();
      }
    });

    test('AND filter across a single-field and a compound index', () async {
      var eqName = where('name').eq('item_c');
      var eqQty = where('qty').eq(5);
      var eqQty2 = where('qty2').eq(10);

      var cursor = collection.find(filter: and([eqName, eqQty, eqQty2]));
      expect(await cursor.length, 1);
    });
  });
}
