import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group('Cursor count() short-circuit', () {
    late Nitrite db;
    late NitriteCollection col;

    setUp(() async {
      db = await Nitrite.builder().openOrCreate();
      col = await db.getCollection('c');
      await col.createIndex(['seq'], indexOptions(IndexType.nonUnique));
      for (var i = 0; i < 20; i++) {
        await col.insert(emptyDocument().put('seq', i % 5).put('n', i));
      }
    });

    tearDown(() async => db.close());

    test('whole-collection count matches map size', () async {
      var cursor = col.find();
      expect(await cursor.count(), 20);
      // parity with streaming length
      expect(await col.find().length, 20);
    });

    test('index-covered count matches streamed length', () async {
      var cursor = col.find(filter: where('seq').eq(2));
      var streamed = await col.find(filter: where('seq').eq(2)).length;
      expect(await cursor.count(), streamed);
      expect(await cursor.count(), 4);
    });

    test('range index-covered count', () async {
      var cursor = col.find(filter: where('seq').gte(0));
      expect(await cursor.count(), 20);
    });

    test('non-indexed filter falls back and is correct', () async {
      var cursor = col.find(filter: where('n').gte(10));
      var streamed = await col.find(filter: where('n').gte(10)).length;
      expect(await cursor.count(), streamed);
      expect(await cursor.count(), 10);
    });

    test('count with limit falls back (not index id count)', () async {
      var cursor = col.find(
        filter: where('seq').gte(0),
        findOptions: limitBy(7),
      );
      expect(await cursor.count(), 7);
    });
  });
}
