import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/document_cursor.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/common/stream/joined_document_stream.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'joined_document_stream_test.mocks.dart';

@GenerateMocks([ProcessorChain])
void main() {
  group("JoinedDocumentStream Test Suite", () {
    late MockProcessorChain processorChain;

    setUp(() {
      processorChain = MockProcessorChain();
      when(processorChain.processAfterRead(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        return Future.value(doc);
      });
      when(processorChain.processBeforeWrite(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        return Future.value(doc);
      });
    });

    test("Test Join", () async {
      var documentCursor = DocumentStream(
          () => Stream.fromIterable([
                Document.createDocument("key", 1),
                Document.createDocument("key", 2),
              ]),
          processorChain,
          FindPlan());

      var lookUp = LookUp("key", "key", "target");
      var joinedDocumentStream = JoinedDocumentStream(
          Stream.fromIterable([
            Document.createDocument("key", 1),
            Document.createDocument("key", 2),
          ]),
          documentCursor,
          lookUp);

      expect(await joinedDocumentStream.toList(), [
        Document.createDocument("key", 1)
          ..put("target", {Document.createDocument("key", 1)}),
        Document.createDocument("key", 2)
          ..put("target", {Document.createDocument("key", 2)}),
      ]);
    });

    test("Test Join with No Match", () async {
      var documentCursor = DocumentStream(
          () => Stream.fromIterable([
                Document.createDocument("key1", 1),
                Document.createDocument("key1", 2),
              ]),
          processorChain,
          FindPlan());

      var lookUp = LookUp("key", "key", "target");
      var joinedDocumentStream = JoinedDocumentStream(
          Stream.fromIterable([
            Document.createDocument("key", 1),
            Document.createDocument("key", 2),
          ]),
          documentCursor,
          lookUp);

      expect(await joinedDocumentStream.toList(), [
        Document.createDocument("key", 1),
        Document.createDocument("key", 2),
      ]);
    });

    test("Test Join with Same Target", () async {
      var documentCursor = DocumentStream(
          () => Stream.fromIterable([
                Document.createDocument("key", 1),
                Document.createDocument("key", 1),
                Document.createDocument("key", 2),
                Document.createDocument("key", 2),
              ]),
          processorChain,
          FindPlan());

      var lookUp = LookUp("key", "key", "key");
      var joinedDocumentStream = JoinedDocumentStream(
          Stream.fromIterable([
            Document.createDocument("key", 1),
            Document.createDocument("key", 2),
          ]),
          documentCursor,
          lookUp);

      expect(await joinedDocumentStream.toList(), [
        Document.createDocument("key", {Document.createDocument("key", 1)}),
        Document.createDocument("key", {Document.createDocument("key", 2)}),
      ]);
    });

    test("Test Join with Wrong Lookup", () async {
      var documentCursor = DocumentStream(
          () => Stream.fromIterable([
                Document.createDocument("key", 1),
                Document.createDocument("key", 2),
              ]),
          processorChain,
          FindPlan());

      var lookUp = LookUp("key", "key", "");
      var joinedDocumentStream = JoinedDocumentStream(
          Stream.fromIterable([
            Document.createDocument("key", 1),
            Document.createDocument("key", 2),
          ]),
          documentCursor,
          lookUp);

      expect(() async => await joinedDocumentStream.toList(),
          throwsInvalidOperationException);
    });
  });
}
