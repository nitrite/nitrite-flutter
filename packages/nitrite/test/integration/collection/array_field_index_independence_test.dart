import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

/// A query's results must not depend on which indexes happen to exist.
/// `field.eq(x)` / `field.within(..)` on a list field is defined by the index
/// path as element containment; before the fix the collection-scan path did
/// whole-value equality, so an indexed array-eq that the planner relegated to
/// a collection scan (e.g. when a range filter on another field claimed the
/// index) silently matched nothing.
void main() {
  group('Array field index independence', () {
    // days 0 & 2 tagged "todo", days 1 & 3 tagged "misc"; created_at = day*1000
    Future<NitriteCollection> seed(bool tagsIndex, bool createdIndex) async {
      var db = await Nitrite.builder().openOrCreate();
      var c = await db.getCollection('array_index_independence');
      if (tagsIndex) await c.createIndex(['tags'], indexOptions(IndexType.nonUnique));
      if (createdIndex) {
        await c.createIndex(['created_at'], indexOptions(IndexType.nonUnique));
      }
      for (var day = 0; day < 4; day++) {
        var tag = day % 2 == 0 ? 'todo' : 'misc';
        await c.insert(createDocument('created_at', day * 1000).put('tags', [tag]));
      }
      return c;
    }

    test('array eq matches by containment without an index', () async {
      var c = await seed(false, false);
      expect(await c.find(filter: where('tags').eq('todo')).length, 2);
      expect(await c.find(filter: where('tags').eq('nope')).length, 0);
    });

    test('array eq result is index-independent', () async {
      var without = await (await seed(false, false)).find(filter: where('tags').eq('todo')).length;
      var with_ = await (await seed(true, false)).find(filter: where('tags').eq('todo')).length;
      expect(without, with_);
      expect(with_, 2);
    });

    test('array eq combined with range when both fields indexed', () async {
      var c = await seed(true, true);
      // day 2 is the only "todo" inside [1000,3000]
      expect(
          await c.find(filter: and([where('tags').eq('todo'), where('created_at').between(1000, 3000)])).length, 1);
      expect(
          await c.find(filter: and([where('created_at').between(1000, 3000), where('tags').eq('todo')])).length, 1);
      expect(
          await c
              .find(filter: and([where('tags').eq('todo'), where('created_at').gte(1000), where('created_at').lte(3000)]))
              .length,
          1);
      expect(await c.find(filter: and([where('tags').eq('todo'), where('created_at').gte(1000)])).length, 1);
    });

    test('array within matches by containment on collection scan', () async {
      var c = await seed(false, true);
      expect(await c.find(filter: where('tags').within(['todo', 'other'])).length, 2);
      expect(
          await c.find(filter: and([where('tags').within(['todo']), where('created_at').between(1000, 3000)])).length, 1);
    });
  });
}
