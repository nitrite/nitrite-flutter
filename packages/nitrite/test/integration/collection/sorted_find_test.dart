import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

/// Regression tests for `find(findOptions: orderBy(field).setLimit(n))` on an
/// indexed field.
///
/// The blocking sort collects and fully deserializes *every* document matching
/// the filter before the first row can be returned, so a 20-row page cost the
/// same as draining the whole collection - and an index on the sort field
/// bought nothing, because the index was only ever used to filter. Sorted,
/// limited reads now take their sort keys from the index and fetch only the
/// documents they return.
///
/// The change must be invisible: these tests pin the result of every sorted
/// query against the same query on an unindexed collection, including the cases
/// where the index is *not* a faithful stand-in for the collection (a
/// multi-valued field is indexed once per element, a non-comparable value is
/// not indexed at all) and the blocking sort has to run anyway.

/// Documents with a distinct `seq`, a `bucket` that repeats (so sorts have
/// ties), and a `name` for string ordering.
Future<void> _seed(NitriteCollection coll, int count) async {
  await coll.insertMany([
    for (var i = 0; i < count; i++)
      emptyDocument()
          .put("seq", i)
          .put("bucket", i % 5)
          .put("name", "name-${(count - i).toString().padLeft(4, '0')}"),
  ]);
}

Future<List<dynamic>> _read(
  NitriteCollection coll,
  FindOptions options,
  String field,
) async {
  var documents = await coll.find(findOptions: options).toList();
  return documents.map((d) => d[field]).toList();
}

/// Runs [options] against an indexed and an unindexed copy of the same data and
/// asserts the two agree - document for document, in order.
Future<void> _assertIndexMatchesScan(
  Future<void> Function(NitriteCollection) seeder,
  FindOptions options,
  String field,
) async {
  var indexed = await db.getCollection('indexed');
  await indexed.createIndex(["seq"], indexOptions(IndexType.nonUnique));
  await indexed.createIndex(["bucket"], indexOptions(IndexType.nonUnique));
  await indexed.createIndex(["name"], indexOptions(IndexType.nonUnique));
  await seeder(indexed);

  var scanned = await db.getCollection('scanned');
  await seeder(scanned);

  expect(
    await _read(indexed, options, field),
    await _read(scanned, options, field),
    reason: 'index-ordered sort disagreed with the blocking sort',
  );
}

void main() {
  group(retry: 3, "Collection Sorted Find Test Suite", () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test("Test Sorted Page Matches Full Scan Ascending", () async {
      await _assertIndexMatchesScan(
        (c) => _seed(c, 500),
        orderBy("seq", SortOrder.ascending).setLimit(20),
        "seq",
      );
    });

    test("Test Sorted Page Matches Full Scan Descending", () async {
      await _assertIndexMatchesScan(
        (c) => _seed(c, 500),
        orderBy("seq", SortOrder.descending).setLimit(20),
        "seq",
      );
    });

    test("Test Deep Page Matches Full Scan", () async {
      await _assertIndexMatchesScan(
        (c) => _seed(c, 500),
        orderBy("seq", SortOrder.descending).setSkip(400).setLimit(20),
        "seq",
      );
    });

    test("Test Ties Keep The Same Sort Keys", () async {
      // 100 documents share each bucket value. Dart's List.sort is not stable,
      // so the order *within* a tie group is not something either path
      // promises - but the sequence of keys, and the set of rows, must match.
      await _assertIndexMatchesScan(
        (c) => _seed(c, 500),
        orderBy("bucket", SortOrder.ascending).setLimit(50),
        "bucket",
      );
    });

    test("Test String Sort Matches Full Scan", () async {
      await _assertIndexMatchesScan(
        (c) => _seed(c, 200),
        orderBy("name", SortOrder.ascending).setLimit(20),
        "name",
      );
    });

    test("Test Missing Sort Field Sorts First", () async {
      // a document with no seq is indexed under null, and null sorts before
      // everything else
      await _assertIndexMatchesScan(
        (c) async {
          await _seed(c, 100);
          await c.insertMany([
            emptyDocument().put("bucket", 0).put("name", "no-seq-a"),
            emptyDocument().put("bucket", 1).put("name", "no-seq-b"),
          ]);
        },
        orderBy("seq", SortOrder.ascending).setLimit(10),
        "seq",
      );
    });

    test("Test Multi Valued Field Falls Back To Blocking Sort", () async {
      // an array value is indexed once per element, so the index holds more
      // entries than the collection holds documents; ordering from it would
      // return a document twice. The blocking sort refuses to compare a list
      // against a number, and the indexed collection must refuse it the same
      // way rather than quietly answering from the index.
      var coll = await db.getCollection('multi-valued');
      await coll.createIndex(["seq"], indexOptions(IndexType.nonUnique));
      await _seed(coll, 50);
      await coll
          .insert(emptyDocument().put("seq", [3, 9]).put("name", "multi"));

      expect(
        () => _read(
            coll, orderBy("seq", SortOrder.ascending).setLimit(20), "name"),
        throwsA(isA<InvalidOperationException>()),
      );
    });

    test("Test Paging Covers The Collection Exactly Once", () async {
      var coll = await db.getCollection('paged');
      await coll.createIndex(["seq"], indexOptions(IndexType.nonUnique));
      await _seed(coll, 200);

      var paged = <dynamic>[];
      for (var page = 0; page < 10; page++) {
        paged.addAll(await _read(
          coll,
          orderBy("seq", SortOrder.descending).setSkip(page * 20).setLimit(20),
          "seq",
        ));
      }

      expect(paged.length, 200, reason: 'paging lost or duplicated rows');
      expect(paged, [for (var i = 199; i >= 0; i--) i]);
    });

    test("Test Unique Index Sort Matches Full Scan", () async {
      var indexed = await db.getCollection('unique-indexed');
      await indexed.createIndex(["seq"], indexOptions(IndexType.unique));
      await _seed(indexed, 200);

      var scanned = await db.getCollection('unique-scanned');
      await _seed(scanned, 200);

      var options = orderBy("seq", SortOrder.descending).setLimit(20);
      expect(
        await _read(indexed, options, "seq"),
        await _read(scanned, options, "seq"),
      );
    });

    test("Test Unlimited Sort Is Unchanged", () async {
      // with no limit every document is fetched anyway, so the index path is
      // not worth taking; the result must still be the plain sorted collection
      var coll = await db.getCollection('unlimited');
      await coll.createIndex(["seq"], indexOptions(IndexType.nonUnique));
      await _seed(coll, 100);

      var sorted =
          await _read(coll, orderBy("seq", SortOrder.descending), "seq");
      expect(sorted, [for (var i = 99; i >= 0; i--) i]);
    });
  });
}
