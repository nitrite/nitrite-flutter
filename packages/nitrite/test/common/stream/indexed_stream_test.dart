import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/indexed_stream.dart';
import 'package:test/test.dart';

import 'indexed_stream_test.mocks.dart';

@GenerateMocks([NitriteMap<NitriteId, Document>])
void main() {
  group("IndexedStream Test Suite", () {
    test("Test with Index", () async {
      var nitriteMap = MockNitriteMap<NitriteId, Document>();
      var indexMap = Stream.fromIterable([
        NitriteId.createId("1"),
        NitriteId.createId("2"),
        NitriteId.createId("3"),
      ]);

      var stream = IndexedStream(indexMap, nitriteMap);
      when(nitriteMap[any])
          .thenAnswer((_) async => documentFromMap({"id": 1, "name": "John"}));

      expect(await stream.toList(), [
        documentFromMap({"id": 1, "name": "John"}),
        documentFromMap({"id": 1, "name": "John"}),
        documentFromMap({"id": 1, "name": "John"}),
      ]);
    });

    test("Test with no Index", () async {
      var nitriteMap = MockNitriteMap<NitriteId, Document>();
      var indexMap = Stream.fromIterable(<NitriteId>[]);

      var stream = IndexedStream(indexMap, nitriteMap);
      when(nitriteMap[any])
          .thenAnswer((_) async => documentFromMap({"id": 1, "name": "John"}));

      expect(await stream.toList(), []);
    });
  });
}
