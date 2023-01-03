import 'package:encrypt/encrypt.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  late ObjectRepository<EncryptedPerson> persons;
  late Processor cvvProcessor;
  late Processor creditCardProcessor;

  group('Field Processor Test Suite', () {
    setUp(() async {
      // setUpLog();
      await setUpNitriteTest();

      var key = Key.fromLength(32);
      var iv = IV.fromLength(16);

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

      print(1);
      await creditCardProcessor.process(persons);
      print(2);
      await persons.addProcessor(creditCardProcessor);
      print(3);


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

      // var documents = await persons.documentCollection?.find();

      await for (var document in documents) {
        print(document);

        // if (document['creditCardNumber'] == '5548960345687452') {
        //   fail('unencrypted secret text found');
        // }

        // if (document['creditCardNumber'] == '5500960345687452') {
        //   fail('unencrypted secret text found');
        // }

        // if (document['cvv'] == '008') {
        //   fail('unencrypted secret text found');
        // }

        // if (document['cvv'] == '007') {
        //   fail('unencrypted secret text found');
        // }
      }
    });

    test('Test Successful Decryption', () async {
      var collection = persons.documentCollection;
      var cursor = await collection?.find();
      print(await cursor?.toList());

      // var cursor = await persons.find(filter: where('name').eq('Jane Doe'));
      // print(await (await persons.find()).toList());
      // var person = await cursor.first;

      // expect(person, isNotNull);
      // expect(person.creditCardNumber, '5500960345687452');
      // expect(person.cvv, '008');

      // cursor = await persons.find(filter: where('name').eq('John Doe'));
      // person = await cursor.first;

      // expect(person, isNotNull);
      // expect(person.creditCardNumber, '5548960345687452');
      // expect(person.cvv, '007');
    });
  });
}
