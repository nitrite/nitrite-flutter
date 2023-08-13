import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/projected_document_stream.dart';
import 'package:test/test.dart';

void main() {
  group(retry: 3, "ProjectedDocumentStream Test Suite", () {
    test("Test Stream with Projection", () async {
      var stream = ProjectedDocumentStream(
          Stream.fromIterable([
            documentFromMap({"id": 1, "name": "John"}),
            documentFromMap({"id": 2, "name": "Jane"}),
            documentFromMap({"id": 3, "name": "Joe"}),
          ]),
          documentFromMap({"name": ""}));
      expect(await stream.toList(), [
        documentFromMap({"name": "John"}),
        documentFromMap({"name": "Jane"}),
        documentFromMap({"name": "Joe"}),
      ]);
    });

    test("Test Stream with no Projection", () async {
      var stream = ProjectedDocumentStream(
          Stream.fromIterable([
            documentFromMap({"id": 1, "name": "John"}),
            documentFromMap({"id": 2, "name": "Jane"}),
            documentFromMap({"id": 3, "name": "Joe"}),
          ]),
          emptyDocument());
      expect(await stream.toList(), [
        emptyDocument(),
        emptyDocument(),
        emptyDocument(),
      ]);
    });
  });
}
