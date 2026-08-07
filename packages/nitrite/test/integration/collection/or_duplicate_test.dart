import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

/// "a" satisfies both branches of [_orFilter], "b" only the second one.
Future<void> _insertDocs() async {
  await collection.insertMany([
    emptyDocument().put("name", "a").put("x", 1).put("y", 2),
    emptyDocument().put("name", "b").put("x", 9).put("y", 2),
  ]);
}

Filter _orFilter() => where("x").eq(1).or(where("y").eq(2));

Future<List<String?>> _names(DocumentCursor cursor) async {
  var documents = await cursor.toList();
  return documents.map((d) => d.get<String>("name")).toList();
}

void main() {
  group(retry: 3, "Collection Or Duplicate Test Suite", () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
      await _insertDocs();
    });

    tearDown(() async {
      await cleanUp();
    });

    test("Test Or Without Index", () async {
      expect(await _names(collection.find(filter: _orFilter())), ["a", "b"]);
      expect(await collection.find(filter: _orFilter()).length, 2);
    });

    test("Test Or With One Indexed Branch", () async {
      await collection.createIndex(["x"], indexOptions(IndexType.nonUnique));

      expect(await _names(collection.find(filter: _orFilter())), ["a", "b"]);
      expect(await collection.find(filter: _orFilter()).length, 2);
    });

    test("Test Or With All Branches Indexed", () async {
      await collection.createIndex(["x"], indexOptions(IndexType.nonUnique));
      await collection.createIndex(["y"], indexOptions(IndexType.nonUnique));

      expect(await _names(collection.find(filter: _orFilter())), ["a", "b"]);
      expect(await collection.find(filter: _orFilter()).length, 2);
    });
  });
}
