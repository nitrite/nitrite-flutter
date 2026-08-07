import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

/// Four documents varying only in which fields they carry:
///  a - name, nick, age, address.city
///  b - name, age, address.city
///  c - name, nick (explicitly null), age
///  d - name, age
Future<void> _insertDocs() async {
  await collection.insertMany([
    emptyDocument()
        .put("name", "a")
        .put("nick", "aa")
        .put("age", 30)
        .put("address", emptyDocument().put("city", "kolkata")),
    emptyDocument()
        .put("name", "b")
        .put("age", 40)
        .put("address", emptyDocument().put("city", "delhi")),
    emptyDocument().put("name", "c").put("nick", null).put("age", 50),
    emptyDocument().put("name", "d").put("age", 60),
  ]);
}

Future<List<String?>> _names(DocumentCursor cursor) async {
  var documents = await cursor.toList();
  return documents.map((d) => d.get<String>("name")).toList();
}

void main() {
  group(retry: 3, "Collection Exists Filter Test Suite", () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
      await _insertDocs();
    });

    tearDown(() async {
      await cleanUp();
    });

    test("Test Exists", () async {
      expect(await _names(collection.find(filter: where("nick").exists())), [
        "a",
        "c",
      ]);
    });

    test("Test Exists Matches Explicit Null", () async {
      // document "c" carries nick = null; notEq(null) cannot express this,
      // which is exactly why the filter exists
      expect(
        await _names(collection.find(filter: where("nick").exists())),
        contains("c"),
      );
      expect(
        await _names(collection.find(filter: where("nick").notEq(null))),
        isNot(contains("c")),
      );
    });

    test("Test Not Exists", () async {
      expect(
        await _names(collection.find(filter: where("nick").exists().not())),
        ["b", "d"],
      );
      // the ~ operator is the same thing
      expect(
        await _names(collection.find(filter: ~where("nick").exists())),
        ["b", "d"],
      );
    });

    test("Test Exists On Every Document", () async {
      expect(await collection.find(filter: where("name").exists()).length, 4);
      expect(await collection.find(filter: where("age").exists()).length, 4);
    });

    test("Test Exists On Unknown Field", () async {
      expect(
        await collection.find(filter: where("unknown").exists()).length,
        0,
      );
      expect(
        await collection.find(filter: where("unknown").exists().not()).length,
        4,
      );
    });

    test("Test Exists On Embedded Field", () async {
      expect(await _names(collection.find(filter: where("address").exists())), [
        "a",
        "b",
      ]);
      expect(
        await _names(collection.find(filter: where("address.city").exists())),
        ["a", "b"],
      );
      expect(
        await collection.find(filter: where("address.pin").exists()).length,
        0,
      );
    });

    test("Test Indexed Field Gives Same Result", () async {
      var beforeIndex = await _names(
        collection.find(filter: where("nick").exists()),
      );
      await collection.createIndex(["nick"], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(["nick"]), isTrue);

      // an index stores a missing field and an explicit null under the same
      // null key, so the filter must stay a collection scan and keep answering
      // the same way once the field is indexed
      expect(
        await _names(collection.find(filter: where("nick").exists())),
        beforeIndex,
      );
      expect(
        await _names(collection.find(filter: where("nick").exists().not())),
        ["b", "d"],
      );
    });

    test("Test Find Plan Uses Collection Scan", () async {
      await collection.createIndex(["nick"], indexOptions(IndexType.nonUnique));
      var findPlan =
          await collection.find(filter: where("nick").exists()).findPlan;

      expect(findPlan.indexDescriptor, isNull);
      expect(findPlan.indexScanFilter, isNull);
      expect(findPlan.collectionScanFilter.toString(), "(nick exists)");
    });

    test("Test Exists Combined With Indexed Filter", () async {
      await collection.createIndex(["age"], indexOptions(IndexType.nonUnique));

      expect(
        await _names(
          collection.find(
            filter: where("age").lt(45).and(where("nick").exists()),
          ),
        ),
        ["a"],
      );
      expect(
        await _names(
          collection.find(
            filter: where("age").lt(45).and(where("nick").exists().not()),
          ),
        ),
        ["b"],
      );
    });

    test("Test Exists With Or", () async {
      expect(
        await _names(
          collection.find(
            filter: where("nick").exists().or(where("address").exists()),
          ),
        ),
        ["a", "b", "c"],
      );
    });

    test("Test Exists After Remove", () async {
      await collection.remove(where("name").eq("a"));
      expect(await _names(collection.find(filter: where("nick").exists())), [
        "c",
      ]);
    });

    test("Test Exists After Update Adds Field", () async {
      await collection.update(
        where("name").eq("d"),
        emptyDocument().put("nick", "dd"),
      );
      expect(await _names(collection.find(filter: where("nick").exists())), [
        "a",
        "c",
        "d",
      ]);
    });

    test("Test Exists String Extension", () async {
      expect(await _names(collection.find(filter: "nick".exists())), [
        "a",
        "c",
      ]);
      expect(
        await _names(collection.find(filter: "nick".exists().not())),
        ["b", "d"],
      );
    });
  });
}
