import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() async {
  group(retry: 3, 'Nitrite Collection Test Suite', () {
    setUp(() {});

    test('Test Attributes', () async {
      var db = await createDb();
      var collection = await db.getCollection("test");

      var attributes = Attributes("test");
      await collection.setAttributes(attributes);

      expect(await collection.getAttributes(), attributes);
    });
  });
}
