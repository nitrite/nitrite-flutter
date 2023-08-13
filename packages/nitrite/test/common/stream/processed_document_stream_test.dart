import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/common/stream/processed_document_stream.dart';
import 'package:test/test.dart';

import 'processed_document_stream_test.mocks.dart';

@GenerateMocks([ProcessorChain])
void main() {
  group(retry: 3, "ProcessedDocumentStream Test Suite", () {
    test("Test Process Reusable", () async {
      var processorChain = MockProcessorChain();
      when(processorChain.processAfterRead(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        doc.put("processed", true);
        return Future.value(doc);
      });
      when(processorChain.processBeforeWrite(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        return Future.value(doc);
      });

      var stream = ProcessedDocumentStream(
          () => Stream.fromIterable([
                createDocument("key", 1),
                createDocument("key", 2),
              ]),
          processorChain);

      expect(await stream.toList(), [
        documentFromMap({"key": 1, "processed": true}),
        documentFromMap({"key": 2, "processed": true}),
      ]);

      expect(await stream.toList(), [
        documentFromMap({"key": 1, "processed": true}),
        documentFromMap({"key": 2, "processed": true}),
      ]);
    });

    test("Test Process Not Reusable", () async {
      var processorChain = MockProcessorChain();
      when(processorChain.processAfterRead(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        doc.put("processed", true);
        return Future.value(doc);
      });
      when(processorChain.processBeforeWrite(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        return Future.value(doc);
      });

      var stream = ProcessedDocumentStream(
          () => Stream.fromIterable([
                createDocument("key", 1),
                createDocument("key", 2),
              ]),
          processorChain,
          reusable: false);

      expect(await stream.toList(), [
        documentFromMap({"key": 1, "processed": true}),
        documentFromMap({"key": 2, "processed": true}),
      ]);

      expect(() async => await stream.toList(), throwsA(isA<StateError>()));
    });
  });
}
