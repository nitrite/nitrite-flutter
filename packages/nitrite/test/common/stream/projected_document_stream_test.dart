import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/projected_document_stream.dart';
import 'package:test/test.dart';

void main() {
  group("ProjectedDocumentStream Test Suite", () {
    test("Test Stream with Projection", () async {
      var stream = ProjectedDocumentStream(
          Stream.fromIterable([
            Document.fromMap({"id": 1, "name": "John"}),
            Document.fromMap({"id": 2, "name": "Jane"}),
            Document.fromMap({"id": 3, "name": "Joe"}),
          ]),
          Document.fromMap({"name": ""})
      );
      expect(await stream.toList(), [
        Document.fromMap({"name": "John"}),
        Document.fromMap({"name": "Jane"}),
        Document.fromMap({"name": "Joe"}),
      ]);
    });

    test("Test Stream with no Projection", () async {
      var stream = ProjectedDocumentStream(
          Stream.fromIterable([
            Document.fromMap({"id": 1, "name": "John"}),
            Document.fromMap({"id": 2, "name": "Jane"}),
            Document.fromMap({"id": 3, "name": "Joe"}),
          ]),
          Document.emptyDocument()
      );
      expect(await stream.toList(), [
        Document.emptyDocument(),
        Document.emptyDocument(),
        Document.emptyDocument(),
      ]);
    });
  });
}