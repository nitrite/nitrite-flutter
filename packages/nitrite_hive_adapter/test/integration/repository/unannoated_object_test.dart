import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';
import 'data/test_objects_decorators.dart';

void main() {
  group(retry: 3, 'Test Unannotated Object Test', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Find', () async {
      var cursor = aObjectRepository.find();
      expect(await cursor.length, 10);

      await aObjectRepository.createIndex(['b.number']);
      cursor = aObjectRepository.find(
          filter: where('b.number').eq(160).not(),
          findOptions:
              orderBy('b.number', SortOrder.ascending).setSkip(0).setLimit(10));
      expect(await cursor.isEmpty, false);

      var findRecord = cursor.project<ClassA>();
      expect(await findRecord.length, 10);
      findRecord.forEach((element) {
        expect(element.b, isNotNull);
        expect(element.blob, isNotEmpty);
        expect(element.string, isNotEmpty);
        expect(element.uid, isNotNull);
      });

      cursor = aObjectRepository.find(
          filter: where('b.number').eq(160).not(),
          findOptions:
              orderBy('b.number', SortOrder.descending).setSkip(2).setLimit(7));
      expect(await cursor.isEmpty, false);
      findRecord = cursor.project<ClassA>();
      expect(await findRecord.length, 7);
      findRecord.forEach((element) {
        expect(element.b, isNotNull);
        expect(element.blob, isNotEmpty);
        expect(element.string, isNotEmpty);
        expect(element.uid, isNotNull);
      });

      var cursorC = cObjectRepository.find(
          filter: where('id').gt(900),
          findOptions:
              orderBy('id', SortOrder.descending).setSkip(2).setLimit(7));
      expect(await cursorC.isEmpty, false);
      var findRecordC = cursorC.project<ClassC>();
      expect(await findRecordC.length, 7);
      findRecordC.forEach((element) {
        expect(element.digit, isNonZero);
        expect(element.id, isNonZero);
        expect(element.parent, isNotNull);
      });
    });

    test('Test Decorated Entity Find', () async {
      var cursor = productRepository.find();
      expect(await cursor.length, 10);
      expect(await cursor.isEmpty, false);

      expect(
          await productRepository
              .hasIndex(["productId.uniqueId", "productId.productCode"]),
          isTrue);
      expect(await productRepository.hasIndex(["manufacturer.name"]), isTrue);
      expect(
          await productRepository
              .hasIndex(["productName", "manufacturer.uniqueId"]),
          isTrue);

      cursor = productRepository.find(
          filter: where('productId.uniqueId')
              .notEq(null)
              .and(where('price').gt(0.0)));

      expect(await cursor.isEmpty, false);
      expect(await cursor.length, 10);

      var miniProducts = cursor.project<MiniProduct>();
      expect(await miniProducts.length, 10);
      miniProducts.forEach((miniProduct) async {
        var products = productRepository.find(
            filter: where('productId.uniqueId').eq(miniProduct.uniqueId));

        var first = await products.first;
        expect(await products.length, 1);
        expect(miniProduct.manufacturerName, first.manufacturer?.name);
        expect(miniProduct.price, first.price);
      });
    });

    test('Test Decorated Entity Find With Tag', () async {
      var cursor = upcomingProductRepository.find();
      expect(await cursor.length, 10);
      expect(await cursor.isEmpty, false);

      expect(
          await upcomingProductRepository
              .hasIndex(["productId.uniqueId", "productId.productCode"]),
          isTrue);
      expect(await upcomingProductRepository.hasIndex(["manufacturer.name"]),
          isTrue);
      expect(
          await upcomingProductRepository
              .hasIndex(["productName", "manufacturer.uniqueId"]),
          isTrue);

      cursor = upcomingProductRepository.find(
          filter: where('productId.uniqueId')
              .notEq(null)
              .and(where('price').gt(0.0)));

      expect(await cursor.isEmpty, false);
      expect(await cursor.length, 10);

      var miniProducts = cursor.project<MiniProduct>();
      expect(await miniProducts.length, 10);
      miniProducts.forEach((miniProduct) async {
        var products = upcomingProductRepository.find(
            filter: where('productId.uniqueId').eq(miniProduct.uniqueId));

        var first = await products.first;
        expect(await products.length, 1);
        expect(miniProduct.manufacturerName, first.manufacturer?.name);
        expect(miniProduct.price, first.price);
      });
    });
  });
}
