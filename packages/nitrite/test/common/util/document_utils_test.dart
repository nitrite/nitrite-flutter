import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/mapper/mappable_mapper.dart';
import 'package:nitrite/src/common/util/document_utils.dart';
import 'package:test/test.dart';

void main() {
  group("Document Utils Test Suite", () {
    test('Test GetDocumentValues', () {
      var document = Document.emptyDocument();
      document.put('_id', '1');
      document.put('name', 'John');
      document.put('age', '30');
      document.put(
          'address',
          Document.emptyDocument()
            ..put('street', '1st Street')
            ..put('city', 'New York')
            ..put('state', 'NY')
            ..put('zip', '10001'));
      document.put(
          'phone',
          Document.emptyDocument()
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
      var nitriteMapper = MappableMapper();
      nitriteMapper.registerMappable(() => _Person());
      nitriteMapper.registerMappable(() => _Address());
      nitriteMapper.registerMappable(() => _Phone());

      var document = skeletonDocument<_Person>(nitriteMapper);
      print(document);
      expect(document.isEmpty, isFalse);
      expect(document.containsKey('name'), isTrue);
      expect(document.containsKey('age'), isTrue);
      expect(document.containsKey('address'), isTrue);
      expect(document.containsKey('phone'), isTrue);
      expect(document.containsKey('_id'), isFalse);
    });

    test('Test SkeletonDocument with value type', () {
      var nitriteMapper = MappableMapper();

      var document = skeletonDocument<int>(nitriteMapper);
      print(document);
      expect(document.isEmpty, isTrue);
    });
  });
}

class _Person implements Mappable {
  String? name;
  int? age;
  _Address? address;
  _Phone? phone;

  @override
  void read(NitriteMapper? mapper, Document document) {
    name = document.get('name');
    age = document.get('age');
    address = mapper?.convert<_Address, Document>(document.get('address'));
    phone = mapper?.convert<_Phone, Document>(document.get('phone'));
  }

  @override
  Document write(NitriteMapper? mapper) {
    var document = Document.emptyDocument();
    document.put('name', name);
    document.put('age', age);
    document.put('address', mapper?.convert<Document, _Address>(address));
    document.put('phone', mapper?.convert<Document, _Phone>(phone));
    return document;
  }
}

class _Address implements Mappable {
  String? street;
  String? city;
  String? state;
  int? zip;

  @override
  void read(NitriteMapper? mapper, Document document) {
    street = document.get('street');
    city = document.get('city');
    state = document.get('state');
    zip = document.get('zip');
  }

  @override
  Document write(NitriteMapper? mapper) {
    var document = Document.emptyDocument();
    document.put('street', street);
    document.put('city', city);
    document.put('state', state);
    document.put('zip', zip);
    return document;
  }
}

class _Phone implements Mappable {
  String? home;
  String? cell;

  @override
  void read(NitriteMapper? mapper, Document document) {
    home = document.get('home');
    cell = document.get('cell');
  }

  @override
  Document write(NitriteMapper? mapper) {
    var document = Document.emptyDocument();
    document.put('home', home);
    document.put('cell', cell);
    return document;
  }
}
