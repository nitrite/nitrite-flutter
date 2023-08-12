import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';

part 'join_test.no2.dart';

void main() {
  late Nitrite db;
  late ObjectRepository<Person> personRepository;
  late ObjectRepository<Address> addressRepository;

  group('Repository Join Test Suite', () {
    setUp(() async {
      setUpLog();
      db = await Nitrite.builder().openOrCreate();
      var mapper = db.config.nitriteMapper as EntityConverterMapper;
      mapper.registerEntityConverter(PersonConverter());
      mapper.registerEntityConverter(PersonDetailsConverter());
      mapper.registerEntityConverter(AddressConverter());

      personRepository = await db.getRepository<Person>();
      addressRepository = await db.getRepository<Address>();

      for (var i = 0; i < 10; i++) {
        var person = Person();
        person.id = i.toString();
        person.name = 'Person $i';

        await personRepository.insert(person);

        var address = Address();
        address.personId = i.toString();
        address.street = 'Street Address $i';

        await addressRepository.insert(address);

        if (i == 5) {
          var address2 = Address();
          address2.personId = i.toString();
          address2.street = 'Street Address 2nd $i';

          await addressRepository.insert(address2);
        }
      }
    });

    tearDown(() async {
      if (!personRepository.isDropped) {
        await personRepository.remove(all);
      }

      if (!addressRepository.isDropped) {
        await addressRepository.remove(all);
      }

      if (db.isClosed) {
        await db.close();
      }
    });

    test('Test Join', () async {
      var lookup = LookUp('id', 'personId', 'addresses');
      var personCursor = personRepository.find();
      var addressCursor = addressRepository.find();

      var result =
          personCursor.leftJoin<Address, PersonDetails>(addressCursor, lookup);
      expect(await result.length, 10);

      await for (var personDetails in result) {
        var addreses = personDetails.addresses;
        if (personDetails.id == '5') {
          expect(addreses?.length, 2);
        } else {
          expect(addreses?.length, 1);
          expect(addreses?[0].personId, personDetails.id);
        }
      }

      personCursor =
          personRepository.find(findOptions: skipBy(0).setLimit(5));
      result =
          personCursor.leftJoin<Address, PersonDetails>(addressCursor, lookup);

      expect(await result.length, 5);
      expect(await result.isEmpty, false);
    });
  });
}

@Entity()
@GenerateConverter()
class Person with _$PersonEntityMixin {
  @Id(fieldName: 'nitriteId')
  NitriteId? nitriteId;
  String? id;
  String? name;

  @override
  String toString() {
    return '{nitriteId: $nitriteId, id: $id, name: $name}';
  }
}

@Entity()
@GenerateConverter()
class Address with _$AddressEntityMixin {
  @Id(fieldName: 'nitriteId')
  NitriteId? nitriteId;
  String? personId;
  String? street;

  @override
  String toString() {
    return '{nitriteId: $nitriteId, personId: $personId, street: $street}';
  }
}

@GenerateConverter()
class PersonDetails {
  @Id(fieldName: 'nitriteId')
  NitriteId? nitriteId;
  String? id;
  String? name;
  List<Address>? addresses;

  @override
  String toString() {
    return '{nitriteId: $nitriteId, id: $id, name: $name, '
        'addresses: $addresses}';
  }
}
