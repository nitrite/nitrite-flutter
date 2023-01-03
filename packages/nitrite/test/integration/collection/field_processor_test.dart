import 'package:encrypt/encrypt.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  late NitriteCollection collection;
  late Processor cvvProcessor;
  late Processor ccProcessor;
  late Encrypter encrypter;
  late IV iv;

  group('Field Processor Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
      var key = Key.fromLength(32);
      iv = IV.fromLength(16);

      encrypter = Encrypter(AES(key, padding: null));
      cvvProcessor = FieldEncrypterProcessor(encrypter, iv, 'cvv');
      ccProcessor = FieldEncrypterProcessor(encrypter, iv, 'creditCardNumber');
      collection = await db.getCollection('encryption-test');
      await collection.addProcessor(ccProcessor);

      var document = createDocument('name', 'John Doe')
        ..put('creditCardNumber', '5548960345687452')
        ..put('cvv', '007')
        ..put('expiryDate', DateTime.now());
      await collection.insert([document]);

      document = createDocument('name', 'Jane Doe')
        ..put('creditCardNumber', '5500960345687452')
        ..put('cvv', '008')
        ..put('expiryDate', DateTime.now());
      await collection.insert([document]);

      await cvvProcessor.process(collection);
      await collection.addProcessor(cvvProcessor);
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Field Encryption in Nitrite Map', () async {
      var nitriteMap = await collection
          .getStore()
          .openMap<NitriteId, Document>('encryption-test');

      var documents = nitriteMap.values();
      await for (var document in documents) {
        if (document['creditCardNumber'] == '5548960345687452') {
          fail('unencrypted secret text found');
        }

        if (document['creditCardNumber'] == '5500960345687452') {
          fail('unencrypted secret text found');
        }

        if (document['cvv'] == '008') {
          fail('unencrypted secret text found');
        }

        if (document['cvv'] == '007') {
          fail('unencrypted secret text found');
        }
      }
    });

    test('Test Successful Decryption', () async {
      var cursor = await collection.find(filter: where('name').eq('Jane Doe'));
      var document = await cursor.first;
      expect(document, isNotNull);

      expect(document['creditCardNumber'], '5500960345687452');
      expect(document['cvv'], '008');

      cursor = await collection.find(filter: where('name').eq('John Doe'));
      document = await cursor.first;
      expect(document, isNotNull);

      expect(document['creditCardNumber'], '5548960345687452');
      expect(document['cvv'], '007');
    });

    test('Test Failed Decryption', () async {
      var key = Key.fromLength(32);
      var wrongEncryptor = Encrypter(AES(key, padding: null));

      collection = await db.getCollection('encryption-test');
      var wrongProcessor = TestProcessor(
        processAfterReadFn: (Document document) async {
          var encrypted = document['creditCardNumber'];
          var raw = wrongEncryptor.decrypt64(encrypted, iv: iv);
          document['creditCardNumber'] = raw;
          return document;
        },
        processBeforeWriteFn: (Document document) async {
          var raw = document['creditCardNumber'];
          var encrypted = encrypter.encrypt(raw, iv: iv);
          document['creditCardNumber'] = encrypted.base64;
          return document;
        },
      );

      collection.addProcessor(wrongProcessor);

      var document = createDocument('name', 'Jane Doe')
        ..put('creditCardNumber', '5500960345687452')
        ..put('cvv', '008')
        ..put('expiryDate', DateTime.now());
      await collection.insert([document]);

      var cursor = await collection.find(filter: where("name").eq("Jane Doe"));
      var first = await cursor.first;

      expect(first['creditCardNumber'], isNot(document['creditCardNumber']));
    });

    test('Test Search on Encrypted Field', () async {
      var cursor = await collection.find(filter: where("cvv").eq("008"));
      expect(await cursor.isEmpty, true);
    });

    test('Test Update Encrypted Field', () async {
      var document = createDocument('name', 'John Doe')
        ..put('creditCardNumber', '00000000000000')
        ..put('cvv', '007')
        ..put('expiryDate', DateTime.now());

      var writeResult =
          await collection.update(where('name').eq('John Doe'), document);
      expect(writeResult.getAffectedCount(), 1);

      var cursor = await collection.find(filter: where('name').eq('John Doe'));
      document = await cursor.first;

      expect(document['creditCardNumber'], '00000000000000');
      expect(document['cvv'], '007');
    });

    test('Test Index on Encrypted Field', () async {
      await collection.createIndex(['cvv']);
      var cursor = await collection.find(filter: where('cvv').eq('008'));
      expect(await cursor.isEmpty, true);
    });
  });
}
