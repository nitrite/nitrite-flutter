import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/document_utils.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group("Document Utils Test Suite", () {
    test('Test GetDocumentValues', () {
      var document = emptyDocument();
      document.put('_id', '1');
      document.put('name', 'John');
      document.put('age', '30');
      document.put(
          'address',
          emptyDocument()
            ..put('street', '1st Street')
            ..put('city', 'New York')
            ..put('state', 'NY')
            ..put('zip', '10001'));
      document.put(
          'phone',
          emptyDocument()
            ..put('home', '212-555-1212')
            ..put('cell', '212-555-1213'));

      var fields =
          Fields.withNames(['name', 'age', 'address.zip', 'phone.home']);
      var fieldValues = getDocumentValues(document, fields);

      expect(fieldValues.nitriteId, NitriteId.createId('1'));
      expect(fieldValues.fields, fields);
      expect(fieldValues.values.length, 4);
      expect(fieldValues.values[0].first, 'name');
      expect(fieldValues.values[0].second, 'John');
      expect(fieldValues.values[1].first, 'age');
      expect(fieldValues.values[1].second, '30');
      expect(fieldValues.values[2].first, 'address.zip');
      expect(fieldValues.values[2].second, '10001');
      expect(fieldValues.values[3].first, 'phone.home');
      expect(fieldValues.values[3].second, '212-555-1212');
    });

    test('Test SkeletonDocument', () {
      var nitriteMapper = EntityConverterMapper();
      nitriteMapper.registerEntityConverter(_PersonConverter());
      nitriteMapper.registerEntityConverter(_AddressConverter());
      nitriteMapper.registerEntityConverter(_PhoneConverter());

      var document = skeletonDocument<_Person>(nitriteMapper);
      expect(document.isEmpty, isFalse);
      expect(document.containsKey('name'), isTrue);
      expect(document.containsKey('age'), isTrue);
      expect(document.containsKey('address'), isTrue);
      expect(document.containsKey('phone'), isTrue);
      expect(document.containsKey('_id'), isFalse);
    });

    test('Test SkeletonDocument with value type', () {
      var nitriteMapper = EntityConverterMapper();
      expect(() => skeletonDocument<int>(nitriteMapper),
          throwsObjectMappingException);
    });
  });
}

class _Person {
  String? name;
  int? age;
  _Address? address;
  _Phone? phone;
}

class _PersonConverter extends EntityConverter<_Person> {
  @override
  _Person fromDocument(Document document, NitriteMapper nitriteMapper) {
    _Person entity = _Person();
    entity.name = document.get('name');
    entity.age = document.get('age');
    entity.address =
        nitriteMapper.tryConvert<_Address, Document>(document.get('address'));
    entity.phone =
        nitriteMapper.tryConvert<_Phone, Document>(document.get('phone'));
    return entity;
  }

  @override
  Document toDocument(_Person entity, NitriteMapper nitriteMapper) {
    var document = emptyDocument();
    document.put('name', entity.name);
    document.put('age', entity.age);
    document.put('address',
        nitriteMapper.tryConvert<Document, _Address>(entity.address));
    document.put(
        'phone', nitriteMapper.tryConvert<Document, _Phone>(entity.phone));
    return document;
  }
}

class _Address {
  String? street;
  String? city;
  String? state;
  int? zip;
}

class _AddressConverter extends EntityConverter<_Address> {
  @override
  _Address fromDocument(Document document, NitriteMapper nitriteMapper) {
    _Address entity = _Address();
    entity.street = document.get('street');
    entity.city = document.get('city');
    entity.state = document.get('state');
    entity.zip = document.get('zip');
    return entity;
  }

  @override
  Document toDocument(_Address entity, NitriteMapper nitriteMapper) {
    var document = emptyDocument();
    document.put('street', entity.street);
    document.put('city', entity.city);
    document.put('state', entity.state);
    document.put('zip', entity.zip);
    return document;
  }
}

class _Phone {
  String? home;
  String? cell;
}

class _PhoneConverter extends EntityConverter<_Phone> {
  @override
  _Phone fromDocument(Document document, NitriteMapper nitriteMapper) {
    _Phone entity = _Phone();
    entity.home = document.get('home');
    entity.cell = document.get('cell');
    return entity;
  }

  @override
  Document toDocument(_Phone entity, NitriteMapper nitriteMapper) {
    var document = emptyDocument();
    document.put('home', entity.home);
    document.put('cell', entity.cell);
    return document;
  }
}
