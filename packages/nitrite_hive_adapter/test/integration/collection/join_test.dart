import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test_loader.dart';

void main() {
  late NitriteCollection foreignCollection;

  group('Collection Join Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();

      foreignCollection = await db.getCollection('foreign');
      await foreignCollection.remove(all);

      var fdoc1 = createDocument('fName', 'fn1')
        ..put('address', 'ABCD Street')
        ..put('telephone', '123456789');

      var fdoc2 = createDocument('fName', 'fn2')
        ..put('address', 'XYZ Street')
        ..put('telephone', '000000000');

      var fdoc3 = createDocument('fName', 'fn2')
        ..put('address', 'Some other Street')
        ..put('telephone', '7893141321');

      await foreignCollection.insertMany([fdoc1, fdoc2, fdoc3]);
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Join All', () async {
      await insert();

      var lookUp = LookUp('firstName', 'fName', 'personalDetails');
      var findResult = await collection.find();
      var result = findResult.leftJoin(await foreignCollection.find(), lookUp);
      expect(await result.length, 3);

      await for (var doc in result) {
        if (doc['firstName'] == 'fn1') {
          var personalDetails = doc['personalDetails'] as Set<Document>;
          expect(personalDetails, isNotNull);
          expect(personalDetails.length, 1);
          expect(personalDetails.toList()[0]['telephone'], '123456789');
        } else if (doc['firstName'] == 'fn2') {
          var personalDetails = doc['personalDetails'] as Set<Document>;
          expect(personalDetails, isNotNull);
          expect(personalDetails.length, 2);
          for (var d in personalDetails) {
            if (d['address'] == 'XYZ Street') {
              expect(d['telephone'], '000000000');
            } else {
              expect(d['telephone'], '7893141321');
            }
          }
        } else if (doc['firstName'] == 'fn3') {
          expect(doc['personalDetails'], isNull);
        }
      }
    });
  });
}
