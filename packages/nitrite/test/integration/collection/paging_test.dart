import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

/// Paging a collection, page by page, against the same rows read in one pass.
///
/// `skip` is served at the source where nothing between the source and the page
/// drops or reorders rows: the offset is reached by stepping over keys, without
/// reading the documents behind them. That is a different code path from a
/// plain scan, so what has to hold is that it lands on exactly the same row -
/// an off-by-one in the skip is a page that silently starts one row late, which
/// no other test would notice. The shapes that must *decline* the push-down (a
/// scanned filter, a blocking sort, an or plan) are here for the same reason:
/// getting those wrong returns the wrong rows rather than merely slowly.
void pagingTests(Future<Nitrite> Function() dbFactory) {
  group('Collection paging', () {
    late Nitrite db;
    late NitriteCollection collection;
    const rows = 300;
    const page = 25;

    setUp(() async {
      db = await dbFactory();
      collection = await db.getCollection('paged');
      for (var i = 0; i < rows; i++) {
        await collection.insert(
            emptyDocument().put('index', i).put('group', i % 5).put('name', 'row $i'));
      }
    });

    tearDown(() async {
      await collection.remove(all);
      await collection.close();
      if (!db.isClosed) await db.close();
    });

    Future<List<Object?>> indexesOf(Filter filter, [FindOptions? options]) async {
      var out = <Object?>[];
      await for (var doc in collection.find(filter: filter, findOptions: options)) {
        out.add(doc['index']);
      }
      return out;
    }

    Future<void> assertPagesMatchFullScan(Filter filter,
        {String? sortField, SortOrder? order, int pageSize = page}) async {
      FindOptions? base =
          sortField == null ? null : orderBy(sortField, order ?? SortOrder.ascending);
      var whole = await indexesOf(filter, base);
      expect(whole, isNotEmpty, reason: 'the fixture must return rows');

      var paged = <Object?>[];
      for (var offset = 0; offset < whole.length; offset += pageSize) {
        var options = sortField == null
            ? skipBy(offset).setLimit(pageSize)
            : (orderBy(sortField, order ?? SortOrder.ascending)
              ..skip = offset
              ..limit = pageSize);
        paged.addAll(await indexesOf(filter, options));
      }
      expect(paged, whole);
    }

    test('every page is the slice of the full scan it claims to be', () async {
      var whole = await indexesOf(all);
      expect(whole.length, rows);

      for (var offset = 0; offset < rows; offset += page) {
        var got = await indexesOf(all, skipBy(offset).setLimit(page));
        var end = offset + page > rows ? rows : offset + page;
        expect(got, whole.sublist(offset, end), reason: 'page at offset $offset');
      }
    });

    test('a page past the end is empty', () async {
      for (var offset in [rows, rows + 1, rows * 3]) {
        expect(await collection.find(findOptions: skipBy(offset).setLimit(page)).length, 0,
            reason: 'a page starting at $offset must be empty, not wrap to the start');
      }
    });

    test('the edges of the skip', () async {
      var whole = await indexesOf(all);
      for (var offset in [0, 1, 2, rows - 2, rows - 1]) {
        var got = await indexesOf(all, skipBy(offset).setLimit(1));
        expect(got, [whole[offset]], reason: 'skip $offset limit 1');
      }
    });

    test('an empty collection pages to nothing', () async {
      var empty = await db.getCollection('empty');
      expect(await empty.find(findOptions: skipBy(0).setLimit(page)).length, 0);
      expect(await empty.find(findOptions: skipBy(10).setLimit(page)).length, 0);
      await empty.close();
    });

    test('an indexed query pages the same way', () async {
      await collection.createIndex(['index'], indexOptions(IndexType.nonUnique));
      await assertPagesMatchFullScan(where('index').gte(100));
    });

    test('a scanned filter still pages correctly', () async {
      await assertPagesMatchFullScan(where('group').eq(3), pageSize: 7);
    });

    test('a blocking sort still pages correctly', () async {
      await assertPagesMatchFullScan(all,
          sortField: 'index', order: SortOrder.descending, pageSize: 31);
    });

    test('an or plan still pages correctly', () async {
      await assertPagesMatchFullScan(
          or([where('index').lt(50), where('index').gte(250)]),
          pageSize: 13);
    });
  });
}

void main() {
  pagingTests(() => Nitrite.builder().fieldSeparator('.').openOrCreate());
}
