import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group("Stack Test Suite", () {
    test("Test GetAffectedCount", () async {
      var writeResult = WriteResult(
          [NitriteId.newId(), NitriteId.newId(), NitriteId.newId()]);
      expect(writeResult.getAffectedCount(), 3);
    });

    test("Test Broadcast", () async {
      var writeResult = WriteResult([
        NitriteId.createId("1"),
        NitriteId.createId("3"),
        NitriteId.createId("2"),
      ]);

      print(writeResult.toList());

      expect(writeResult, [
        NitriteId.createId("1"),
        NitriteId.createId("3"),
        NitriteId.createId("2")
      ]);
    });
  });
}
