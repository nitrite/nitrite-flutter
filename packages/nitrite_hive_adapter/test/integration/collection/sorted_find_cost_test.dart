import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

/// The cost half of the core package's `sorted_find_test.dart`, which needs a
/// store that actually serializes documents.
///
/// A blocking sort deserializes every stored document to read one field, so
/// `orderBy(indexed).setLimit(20)` cost what draining the whole collection
/// cost - and the gap grows with document size, not just document count.
/// Taking the sort keys from the index removes the decode: over 2000 rows
/// carrying a 150-element array the sorted page went from ~342ms to ~5ms.

const _rows = 2000;

Future<double> _sortedPageCost(String name, int payloadSize) async {
  var coll = await db.getCollection(name);
  await coll.createIndex(["seq"], indexOptions(IndexType.nonUnique));

  await coll.insertMany([
    for (var i = 0; i < _rows; i++)
      payloadSize == 0
          ? emptyDocument().put("seq", i)
          : emptyDocument().put("seq", i).put("payload", [
              for (var w = 0; w < payloadSize; w++)
                emptyDocument().put("text", "word$w").put("start", w * 300),
            ]),
  ]);

  var page = orderBy("seq", SortOrder.descending).setLimit(1);
  Future<void> run() => coll.find(findOptions: page).toList().then((_) {});

  await run(); // warm
  var watch = Stopwatch()..start();
  for (var i = 0; i < 3; i++) {
    await run();
  }
  return watch.elapsedMicroseconds / 3000.0;
}

void main() {
  group(retry: 3, "Sorted Find Cost Test Suite", () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    /// The same query, the same row count, the same index - only the size of
    /// the documents differs. A sorted page that decodes every row pays for the
    /// payload of every row, so the fat collection costs many times the lean
    /// one. A sorted page that decodes only the row it returns costs about the
    /// same either way.
    ///
    /// Both halves walk an index of identical size and shape, so that cost
    /// cancels; what does not cancel is the payload of the rows each one
    /// decodes. The page is deliberately one row rather than twenty: returning
    /// a fat document legitimately costs more than returning a lean one, and
    /// that difference is the floor of this ratio, so the fewer rows the page
    /// returns the more of the ratio is the [_rows] rows it should never have
    /// touched.
    ///
    /// Deliberately not "sorted page vs. full drain", whose halves share no
    /// work at all. Both halves here are measured back to back, under whatever
    /// load the machine is under.
    test("Test Sorted Page Cost Does Not Follow Document Size", () async {
      var lean = await _sortedPageCost('lean', 0);
      var fat = await _sortedPageCost('fat', 150);

      expect(
        fat < lean * 3,
        isTrue,
        reason: 'a sorted page over fat documents took ${fat}ms against '
            '${lean}ms over lean ones, same row count - it is still decoding '
            'rows it discards',
      );
    }, timeout: Timeout(Duration(minutes: 2)));
  });
}
