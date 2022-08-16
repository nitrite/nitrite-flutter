import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/sorted_document_stream.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group("SortedDocumentStream Test Suite", () {
    test("Test Stream with Descending Sort Single Field", () async {
      FindPlan findPlan = FindPlan();
      findPlan.blockingSortOrder = [
        Pair("id", SortOrder.descending),
      ];

      var stream = SortedDocumentStream(
          findPlan,
          Stream.fromIterable([
            Document.fromMap({"id": 1, "name": "John"}),
            Document.fromMap({"id": 2, "name": "Jane"}),
            Document.fromMap({"id": 3, "name": "Joe"}),
          ]));

      expect(await stream.toList(), [
        Document.fromMap({"id": 3, "name": "Joe"}),
        Document.fromMap({"id": 2, "name": "Jane"}),
        Document.fromMap({"id": 1, "name": "John"}),
      ]);
    });

    test("Test Stream with Ascending Sort Single Field", () async {
      FindPlan findPlan = FindPlan();
      findPlan.blockingSortOrder = [
        Pair("id", SortOrder.ascending),
      ];

      var stream = SortedDocumentStream(
          findPlan,
          Stream.fromIterable([
            Document.fromMap({"id": 1, "name": "John"}),
            Document.fromMap({"id": 3, "name": "Joe"}),
            Document.fromMap({"id": 2, "name": "Jane"}),
          ]));

      expect(await stream.toList(), [
        Document.fromMap({"id": 1, "name": "John"}),
        Document.fromMap({"id": 2, "name": "Jane"}),
        Document.fromMap({"id": 3, "name": "Joe"}),
      ]);
    });

    test("Test Stream with Descending Sort Multiple Fields", () async {
      FindPlan findPlan = FindPlan();
      findPlan.blockingSortOrder = [
        Pair("id", SortOrder.descending),
        Pair("age", SortOrder.ascending),
      ];

      var stream = SortedDocumentStream(
          findPlan,
          Stream.fromIterable([
            Document.fromMap({"id": 1, "age": 20}),
            Document.fromMap({"id": 1, "age": 30}),
            Document.fromMap({"id": 2, "age": 40}),
            Document.fromMap({"id": 3, "age": 50}),
          ]));

      expect(await stream.toList(), [
        Document.fromMap({"id": 3, "age": 50}),
        Document.fromMap({"id": 2, "age": 40}),
        Document.fromMap({"id": 1, "age": 20}),
        Document.fromMap({"id": 1, "age": 30}),
      ]);
    });

    test("Test Stream with Descending Sort Multiple Fields 2", () async {
      FindPlan findPlan = FindPlan();
      findPlan.blockingSortOrder = [
        Pair("id", SortOrder.descending),
        Pair("age", SortOrder.descending),
      ];

      var stream = SortedDocumentStream(
          findPlan,
          Stream.fromIterable([
            Document.fromMap({"id": 1, "age": 20}),
            Document.fromMap({"id": 1, "age": 30}),
            Document.fromMap({"id": 2, "age": 40}),
            Document.fromMap({"id": 3, "age": 50}),
          ]));

      expect(await stream.toList(), [
        Document.fromMap({"id": 3, "age": 50}),
        Document.fromMap({"id": 2, "age": 40}),
        Document.fromMap({"id": 1, "age": 30}),
        Document.fromMap({"id": 1, "age": 20}),
      ]);
    });

    test("Test Stream with Null Values", () async {
      FindPlan findPlan = FindPlan();
      findPlan.blockingSortOrder = [
        Pair("id", SortOrder.ascending),
        Pair("age", SortOrder.ascending),
      ];

      var stream = SortedDocumentStream(
          findPlan,
          Stream.fromIterable([
            Document.fromMap({"id": 1, "age": 20}),
            Document.fromMap({"id": 1}),
            Document.fromMap({"id": 2, "age": 40}),
            Document.fromMap({"id": 3, "age": 50}),
          ]));

      expect(await stream.toList(), [
        Document.fromMap({"id": 1}),
        Document.fromMap({"id": 1, "age": 20}),
        Document.fromMap({"id": 2, "age": 40}),
        Document.fromMap({"id": 3, "age": 50}),
      ]);
    });

    test("Test Stream with Non-Comparable Values", () async {
      FindPlan findPlan = FindPlan();
      findPlan.blockingSortOrder = [
        Pair("id", SortOrder.ascending),
        Pair("age", SortOrder.ascending),
      ];

      var stream = SortedDocumentStream(
          findPlan,
          Stream.fromIterable([
            Document.fromMap({"id": 1, "age": 20}),
            Document.fromMap({"id": 1, "age": Pair("name", "John")}),
            Document.fromMap({"id": 2, "age": 40}),
            Document.fromMap({"id": 3, "age": 50}),
          ]));

      expect(
          () async => await stream.toList(), throwsInvalidOperationException);
    });
  });
}
