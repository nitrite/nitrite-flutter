import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/filtered_stream.dart';
import 'package:test/test.dart';

import 'filtered_stream_test.mocks.dart';

@GenerateMocks([Filter])
void main() {
  group("FilteredStream Test Suite", () {

    test("Test Stream with Filter 1", () async {
      var filter = MockFilter();

      Stream<Document> stream = FilteredStream(
        Stream.fromIterable([
          Document.fromMap({"id": 1, "name": "John"}),
          Document.fromMap({"id": 2, "name": "Jane"}),
          Document.fromMap({"id": 3, "name": "Joe"}),
        ]),
        filter
      );

      when(filter.apply(any)).thenReturn(true);
      expect(await stream.toList(), [
        Document.fromMap({"id": 1, "name": "John"}),
        Document.fromMap({"id": 2, "name": "Jane"}),
        Document.fromMap({"id": 3, "name": "Joe"}),
      ]);
      verify(filter.apply(any)).called(3);
    });

    test("Test Stream with Filter 2", () async {
      var filter = MockFilter();

      Stream<Document> stream = FilteredStream(
        Stream.fromIterable([
          Document.fromMap({"id": 1, "name": "John"}),
          Document.fromMap({"id": 2, "name": "Jane"}),
          Document.fromMap({"id": 3, "name": "Joe"}),
        ]),
        filter
      );

      when(filter.apply(any)).thenReturn(false);
      expect(await stream.toList(), []);
      verify(filter.apply(any)).called(3);
    });

    test("Test Stream with ALL Filter", () async {
      Stream<Document> stream = FilteredStream(
          Stream.fromIterable([
            Document.fromMap({"id": 1, "name": "John"}),
            Document.fromMap({"id": 2, "name": "Jane"}),
            Document.fromMap({"id": 3, "name": "Joe"}),
          ]),
          all
      );

      expect(await stream.toList(), [
        Document.fromMap({"id": 1, "name": "John"}),
        Document.fromMap({"id": 2, "name": "Jane"}),
        Document.fromMap({"id": 3, "name": "Joe"}),
      ]);
    });
  });
}