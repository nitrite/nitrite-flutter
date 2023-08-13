import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group(retry: 3, 'Nitrite Builder Test Suite', () {
    Nitrite? db;

    tearDown(() async {
      NitriteConfig.fieldSeparator = '.';
      if (db != null && !db!.isClosed) {
        await db!.close();
      }
    });

    test('Test Field Separator', () async {
      var builder = Nitrite.builder();
      db = await builder.fieldSeparator('::').openOrCreate();

      var document =
          createDocument('address', createDocument('street', 'ABCD Road'))
              .put('colorCodes', [
        createDocument('color', 'Red'),
        createDocument('color', 'Green'),
      ]);

      var street = document['address::street'] as String?;
      expect(street, 'ABCD Road');

      street = document['address.street'];
      expect(street, isNull);

      var color = document['colorCodes::1::color'];
      expect(color, 'Green');
    });
  });
}
