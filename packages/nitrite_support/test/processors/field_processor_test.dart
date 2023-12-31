import 'package:encrypt/encrypt.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/processors/string_field_encryption_processor.dart';
import 'package:test/test.dart';

late Nitrite db;

void main() {
  late NitriteCollection collection;
  late Processor cvvProcessor;

  group(retry: 3, 'Field Processor Test Suite', () {
    setUp(() async {
      await setUpNitriteTest();

      cvvProcessor = StringFieldEncryptionProcessor()
        ..addFields(['cvv', 'creditCardNumber']);
      collection = await db.getCollection('encryption-test');
      collection.addProcessor(cvvProcessor);

      var document = createDocument('name', 'John Doe')
        ..put('creditCardNumber', '5548960345687452')
        ..put('cvv', '007')
        ..put('expiryDate', DateTime.now());
      await collection.insert(document);

      document = createDocument('name', 'Jane Doe')
        ..put('creditCardNumber', '5500960345687452')
        ..put('cvv', '008')
        ..put('expiryDate', DateTime.now());
      await collection.insert(document);

      await cvvProcessor.process(collection);
      collection.addProcessor(cvvProcessor);
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
      var cursor = collection.find(filter: where('name').eq('Jane Doe'));
      var document = await cursor.first;
      expect(document, isNotNull);

      expect(document['creditCardNumber'], '5500960345687452');
      expect(document['cvv'], '008');

      cursor = collection.find(filter: where('name').eq('John Doe'));
      document = await cursor.first;
      expect(document, isNotNull);

      expect(document['creditCardNumber'], '5548960345687452');
      expect(document['cvv'], '007');
    });

    test('Test Failed Decryption', () async {
      var key = Key.fromLength(32);
      var wrongEncryptor = Encrypter(AES(key, padding: null));
      var encryptor = Encrypter(AES(key));

      collection = await db.getCollection('encryption-test');
      var wrongProcessor = TestProcessor(
        processAfterReadFn: (Document document) async {
          var encrypted = document['creditCardNumber'];
          var raw = wrongEncryptor.decrypt64(encrypted, iv: IV.fromLength(16));
          document['creditCardNumber'] = raw;
          return document;
        },
        processBeforeWriteFn: (Document document) async {
          var raw = document['creditCardNumber'];
          var encrypted = encryptor.encrypt(raw, iv: IV.fromLength(16));
          document['creditCardNumber'] = encrypted.base64;
          return document;
        },
      );

      collection.addProcessor(wrongProcessor);

      var document = createDocument('name', 'Jane Doe')
        ..put('creditCardNumber', '5500960345687452')
        ..put('cvv', '008')
        ..put('expiryDate', DateTime.now());
      await collection.insert(document);

      var cursor = collection.find(filter: where("name").eq("Jane Doe"));
      var first = await cursor.first;

      expect(first['creditCardNumber'], isNot(document['creditCardNumber']));
    });

    test('Test Search on Encrypted Field', () async {
      var cursor = collection.find(filter: where("cvv").eq("008"));
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

      var cursor = collection.find(filter: where('name').eq('John Doe'));
      document = await cursor.first;

      expect(document['creditCardNumber'], '00000000000000');
      expect(document['cvv'], '007');
    });

    test('Test Index on Encrypted Field', () async {
      await collection.createIndex(['cvv']);
      var cursor = collection.find(filter: where('cvv').eq('008'));
      expect(await cursor.isEmpty, true);
    });

    test('Test Encryption with Password', () async {
      var password = 'password@123';

      var firstNameProcessor = StringFieldEncryptionProcessor(password)
        ..addFields(['firstName']);

      collection = await db.getCollection('test');
      collection.addProcessor(firstNameProcessor);

      var document = createDocument('name', 'John Doe')
        ..put('creditCardNumber', '5548960345687452')
        ..put('cvv', '007')
        ..put('expiryDate', DateTime.now());
      await collection.insert(document);

      document = createDocument('name', 'Jane Doe')
        ..put('creditCardNumber', '5500960345687452')
        ..put('cvv', '008')
        ..put('expiryDate', DateTime.now());
      await collection.insert(document);

      var nitriteMap =
          await collection.getStore().openMap<NitriteId, Document>('test');

      var documents = nitriteMap.values();
      await for (var document in documents) {
        if (document['firstName'] == 'John Doe') {
          fail('unencrypted secret text found');
        }

        if (document['firstName'] == 'Jane Doe') {
          fail('unencrypted secret text found');
        }
      }

      var cursor = collection.find(filter: where('cvv').eq('007'));
      document = await cursor.first;
      expect(document, isNotNull);
      expect(document['name'], 'John Doe');

      cursor = collection.find(filter: where('cvv').eq('008'));
      document = await cursor.first;
      expect(document, isNotNull);
      expect(document['name'], 'Jane Doe');
    });
  });
}

Future<void> setUpNitriteTest() async {
  db = await Nitrite.builder()
      .fieldSeparator('.')
      .openOrCreate(username: 'test', password: 'test');
}

Future<void> cleanUp() async {
  if (!db.isClosed) {
    await db.close();
  }
}

class TestProcessor extends Processor {
  final Future<Document> Function(Document document) processAfterReadFn;
  final Future<Document> Function(Document document) processBeforeWriteFn;

  TestProcessor({
    required this.processAfterReadFn,
    required this.processBeforeWriteFn,
  });

  @override
  Future<Document> processAfterRead(Document document) {
    return processAfterReadFn(document);
  }

  @override
  Future<Document> processBeforeWrite(Document document) {
    return processBeforeWriteFn(document);
  }
}
