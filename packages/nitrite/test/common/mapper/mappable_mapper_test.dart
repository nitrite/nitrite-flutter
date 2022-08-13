import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/mapper/mappable_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('MappableMapper Test Suite', () {
    test('Test Convert Value Type', () {
      var mapper = MappableMapper();
      {
        var value = mapper.convert<int, int>(1);
        expect(value, 1);
      }

      {
        var value = mapper.convert<double, double>(1.0);
        expect(value, 1.0);
      }

      {
        var value = mapper.convert<String, String>('1');
        expect(value, '1');
      }

      {
        var value = mapper.convert<bool, bool>(true);
        expect(value, true);
      }

      {
        var value = mapper.convert<Null, Null>(null);
        expect(value, null);
      }

      {
        var value = mapper.convert<DateTime, DateTime>(DateTime(2020, 1, 1));
        expect(value, DateTime(2020, 1, 1));
      }

      {
        var value = mapper.convert<Duration, Duration>(Duration(days: 1));
        expect(value, Duration(days: 1));
      }

      {
        var value =
            mapper.convert<NitriteId, NitriteId>(NitriteId.createId('1'));
        expect(value, NitriteId.createId('1'));
      }
    });

    test('Test Convert From Document', () {
      var mapper = MappableMapper();
      {
        var value = mapper.convert<Document, Document>(
            Document.createDocument("key", "value"));
        expect(value, Document.createDocument("key", "value"));
      }
    });

    test("Test Convert Non Mappable To Document", () {
      var mapper = MappableMapper();
      var a = _A("test");
      expect(() => mapper.convert<Document, _A>(a),
          throwsA(TypeMatcher<ObjectMappingException>()));
    });

    test("Test Convert Document To Non Mappable", () {
      var mapper = MappableMapper();
      expect(
          () => mapper
              .convert<_A, Document>(Document.createDocument("key", "value")),
          throwsA(TypeMatcher<ObjectMappingException>()));
    });

    test("Test Convert Document To Mappable", () {
      var mapper = MappableMapper();
      mapper.registerMappable(() => _B());

      var b = mapper
          .convert<_B, Document>(Document.createDocument("value", "test"));
      expect(b, isNotNull);
      expect(b?.value, "test");
    });

    test("Test Convert Mappable To Document", () {
      var mapper = MappableMapper();
      var b = _B("test");
      var document = mapper.convert<Document, _B>(b);
      expect(document, isNotNull);
      expect(document?.get("value"), "test");
    });

    test("Test Convert No Factory", () {
      var mapper = MappableMapper();

      expect(
          () => mapper
              .convert<_B, Document>(Document.createDocument("value", "test")),
          throwsA(TypeMatcher<ObjectMappingException>()));
    });

    test("Test IsValueType", () {
      var mapper = MappableMapper();
      expect(mapper.isValueType(), isFalse); // no type arguments
      expect(mapper.isValueType<int>(), isTrue);
      expect(mapper.isValueType<double>(), isTrue);
      expect(mapper.isValueType<String>(), isTrue);
      expect(mapper.isValueType<bool>(), isTrue);
      expect(mapper.isValueType<Null>(), isTrue);
      expect(mapper.isValueType<DateTime>(), isTrue);
      expect(mapper.isValueType<Duration>(), isTrue);
      expect(mapper.isValueType<NitriteId>(), isTrue);
      expect(mapper.isValueType<Document>(), isFalse);

      expect(mapper.isValueType<_A>(), isFalse);
      expect(mapper.isValueType<_B>(), isFalse);

      mapper.addValueType<_A>();
      expect(mapper.isValueType<_A>(), isTrue);
      expect(mapper.isValueType<_B>(), isFalse);

      mapper.addValueType<_B>();
      expect(mapper.isValueType<_A>(), isTrue);
      expect(mapper.isValueType<_B>(), isTrue);
    });

    test("Test IsValue", () {
      var mapper = MappableMapper();
      expect(mapper.isValue(1), isTrue);
      expect(mapper.isValue(1.0), isTrue);
      expect(mapper.isValue("1"), isTrue);
      expect(mapper.isValue(true), isTrue);
      expect(mapper.isValue(null), isTrue);
      expect(mapper.isValue(DateTime(2020, 1, 1)), isTrue);
      expect(mapper.isValue(Duration(days: 1)), isTrue);
      expect(mapper.isValue(NitriteId.createId('1')), isTrue);
      expect(mapper.isValue(Document.createDocument("key", "value")), isFalse);

      mapper.addValueType<_A>();
      expect(mapper.isValue(_A("test")), isTrue);
      expect(mapper.isValue(_B("test")), isFalse);

      mapper.addValueType<_B>();
      expect(mapper.isValue(_A("test")), isTrue);
      expect(mapper.isValue(_B("test")), isTrue);
    });

    test("Test NewInstance", () {
      var mapper = MappableMapper();
      expect(() => mapper.newInstance<int>(),
          throwsA(TypeMatcher<ObjectMappingException>()));
      expect(() => mapper.newInstance<_B>(),
          throwsA(TypeMatcher<ObjectMappingException>()));

      mapper.registerMappable(() => _B());
      expect(mapper.newInstance<_B>(), isNotNull);
    });
  });
}

class _A {
  final String value;
  _A(this.value);
}

class _B implements Mappable {
  String? value;

  _B([this.value]);

  @override
  void read(NitriteMapper? mapper, Document document) {
    value = document.get('value');
  }

  @override
  Document write(NitriteMapper? mapper) {
    return Document.createDocument('value', value);
  }
}
