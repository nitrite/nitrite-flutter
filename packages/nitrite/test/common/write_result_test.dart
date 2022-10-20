import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group("Stack Test Suite", () {
    test("Test GetAffectedCount", () async {
      var writeResult = WriteResult(Stream.fromIterable(
          [NitriteId.newId(), NitriteId.newId(), NitriteId.newId()]));
      await expectLater(writeResult.getAffectedCount(), completion(3));
    });

    test("Test Broadcast", () async {
      var writeResult = WriteResult(Stream.fromIterable([
        NitriteId.createId("1"),
        NitriteId.createId("3"),
        NitriteId.createId("2"),
      ]));

      writeResult.listen(print);
      writeResult.listen(print);

      await expectLater(writeResult, emitsInOrder([
        NitriteId.createId("1"),
        NitriteId.createId("3"),
        NitriteId.createId("2")
      ]));

    });
  });
}
