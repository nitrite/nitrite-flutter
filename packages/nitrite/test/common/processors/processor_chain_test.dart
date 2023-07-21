import 'dart:async';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/document_cursor.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:test/test.dart';

import 'processor_chain_test.mocks.dart';

@GenerateMocks([
  Processor,
  NitriteCollection,
])
void main() {
  group("ProcessorChain Test Suite", () {
    test("Test Remove", () {
      var processorChain = ProcessorChain();
      var processor = MockProcessor();
      expect(processorChain.processors.isEmpty, isTrue);
      processorChain.add(processor);
      expect(processorChain.processors.isNotEmpty, isTrue);
      processorChain.remove(processor);
      expect(processorChain.processors.isEmpty, isTrue);
    });

    test("Test Process Before Write", () async {
      var processorChain = ProcessorChain();
      var processor = MockProcessor();
      when(processor.processBeforeWrite(any)).thenAnswer(
          (_) => Future.value(Document.createDocument("processed", true)));
      processorChain.add(processor);

      var document = Document.emptyDocument();
      expect(document.containsKey("processed"), isFalse);
      expect(processorChain.processors.isNotEmpty, isTrue);

      var doc = await processorChain.processBeforeWrite(document);
      expect(doc, isNotNull);
      expect(doc.containsKey("processed"), isTrue);
      expect(doc.get("processed"), isTrue);

      verify(processor.processBeforeWrite(any)).called(1);
    });

    test("Test Process After Read", () async {
      var processorChain = ProcessorChain();
      var processor = MockProcessor();
      when(processor.processAfterRead(any))
          .thenAnswer((_) => Future.value(Document.emptyDocument()));
      processorChain.add(processor);

      var document = Document.createDocument("processed", true);
      expect(document.isEmpty, isFalse);
      expect(processorChain.processors.isNotEmpty, isTrue);

      var doc = await processorChain.processAfterRead(document);
      expect(doc, isNotNull);
      expect(doc.containsKey("processed"), isFalse);
      expect(doc.isEmpty, isTrue);
    });

    test("Test Process", () async {
      var mockProcessor = MockProcessor();
      var spyProcessor = _SpyProcessor(mockProcessor);
      var collection = MockNitriteCollection();
      var documentCursor = DocumentStream(
          () => Stream.fromIterable([
                Document.createDocument("key", 1),
                Document.createDocument("key", 2),
              ]),
          ProcessorChain([spyProcessor]),
          () async => FindPlan());

      when(collection.find()).thenAnswer((_) => documentCursor);
      when(collection.update(any, any, any))
          .thenAnswer((_) => Future.value(WriteResult([NitriteId.newId()])));

      when(mockProcessor.processBeforeWrite(any)).thenAnswer(
          (_) => Future.value(Document.createDocument("processed", true)));

      when(mockProcessor.processAfterRead(any)).thenAnswer((invocation) {
        var doc = invocation.positionalArguments.first as Document;
        return Future.value(doc);
      });

      await spyProcessor.process(collection);

      verify(mockProcessor.processBeforeWrite(any))
          .called(2); // during process()

      verify(collection.find()).called(1);
      verify(mockProcessor.processAfterRead(any))
          .called(2); // during cursor for-await loop
      verify(collection.update(any, any, any)).called(2);
    });
  });
}

class _SpyProcessor extends Processor {
  final MockProcessor _mockProcessor;
  _SpyProcessor(this._mockProcessor);

  @override
  Future<Document> processAfterRead(Document document) {
    return _mockProcessor.processAfterRead(document);
  }

  @override
  Future<Document> processBeforeWrite(Document document) {
    return _mockProcessor.processBeforeWrite(document);
  }
}
