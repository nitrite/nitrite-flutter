import 'package:encrypt/encrypt.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import '../string_field_encryption_processor.dart';
import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  late ObjectRepository<EncryptedPerson> persons;
  late Processor cvvProcessor;
  late Processor creditCardProcessor;
  late IV iv;

  group('Field Processor Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();

      var key = Key.fromLength(32);
      iv = IV.fromLength(16);

      persons = await db.getRepository<EncryptedPerson>();
      cvvProcessor = FieldEncrypterProcessor(
          Encrypter(AES(key, padding: null)), iv, 'cvv');
      creditCardProcessor = FieldEncrypterProcessor(
          Encrypter(AES(key, padding: null)), iv, 'creditCardNumber');

      await persons.addProcessor(cvvProcessor);

      var person = EncryptedPerson();
      person.name = 'John Doe';
      person.creditCardNumber = '5548960345687452';
      person.cvv = '007';
      person.expiryDate = DateTime.now();
      await persons.insert([person]);

      await creditCardProcessor.process(persons);
      await persons.addProcessor(creditCardProcessor);

      person = EncryptedPerson();
      person.name = 'Jane Doe';
      person.creditCardNumber = '5500960345687452';
      person.cvv = '008';
      person.expiryDate = DateTime.now();

      await persons.insert([person]);
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Field Encryption in NitriteMap', () async {
      var store = persons.documentCollection?.getStore();
      var nitriteMapper = db.config.nitriteMapper;
      var nitriteMap = await store?.openMap<NitriteId, Document>(
          findRepositoryNameByType<EncryptedPerson>(nitriteMapper));

      var documents = nitriteMap?.values() as Stream<Document>;
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
      var cursor = await persons.find(filter: where('name').eq('Jane Doe'));
      var person = await cursor.first;

      expect(person, isNotNull);
      expect(person.creditCardNumber, '5500960345687452');
      expect(person.cvv, '008');

      cursor = await persons.find(filter: where('name').eq('John Doe'));
      person = await cursor.first;

      expect(person, isNotNull);
      expect(person.creditCardNumber, '5548960345687452');
      expect(person.cvv, '007');
    });

    test('Test Failed Decryption', () async {
      var testPersons = await db.getRepository<EncryptedPerson>(key: 'test');
      var key = Key.fromLength(32);
      var wrongEncryptor = Encrypter(AES(key, padding: null));

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

      await testPersons.addProcessor(wrongProcessor);

      var person = EncryptedPerson();
      person.name = 'John Doe';
      person.creditCardNumber = '5548960345687452';
      person.cvv = '007';
      person.expiryDate = DateTime.now();
      await testPersons.insert([person]);

      person = EncryptedPerson();
      person.name = 'Jane Doe';
      person.creditCardNumber = '5500960345687452';
      person.cvv = '008';
      person.expiryDate = DateTime.now();

      await testPersons.insert([person]);

      var cursor = await testPersons.find(filter: where("name").eq("Jane Doe"));
      var first = await cursor.first;
      expect(first.creditCardNumber, isNot(person.creditCardNumber));
    });

    test('Test Search on Encrypted Field', () async {
      var cursor = await persons.find(filter: where('cvv').eq('008'));
      expect(await cursor.isEmpty, true);
    });

    test('Test Update Encrypted Field', () async {
      var person = EncryptedPerson();
      person.name = 'John Doe';
      person.creditCardNumber = '00000000000000';
      person.cvv = '007';
      person.expiryDate = DateTime.now();

      var writeResult =
          await persons.update(where('name').eq('John Doe'), person);
      expect(writeResult.getAffectedCount(), 1);

      var cursor = await persons.find(filter: where('name').eq('John Doe'));
      person = await cursor.first;
      expect(person, isNotNull);

      expect(person.creditCardNumber, '00000000000000');
      expect(person.cvv, '007');
    });

    test('Test Index on Encrypted Field', () async {
      await persons.createIndex(['cvv']);
      var cursor = await persons.find(filter: where('cvv').eq('008'));
      expect(await cursor.isEmpty, true);
    });
  });
}
