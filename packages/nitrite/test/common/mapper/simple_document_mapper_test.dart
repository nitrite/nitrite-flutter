import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group('MappableMapper Test Suite', () {
    test('Test Convert Value Type', () {
      var mapper = SimpleDocumentMapper();
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
      var mapper = SimpleDocumentMapper();
      {
        var value = mapper.convert<Document, Document>(
            Document.createDocument("key", "value"));
        expect(value, Document.createDocument("key", "value"));
      }
    });

    test("Test Convert To Document without EntityConverter", () {
      var mapper = SimpleDocumentMapper();
      var a = _A("test");
      expect(
          () => mapper.convert<Document, _A>(a), throwsObjectMappingException);
    });

    test("Test Convert Document To Entity without EntityConverter", () {
      var mapper = SimpleDocumentMapper();
      expect(
          () => mapper
              .convert<_A, Document>(Document.createDocument("key", "value")),
          throwsObjectMappingException);
    });

    test("Test Convert Document To Entity with EntityConverter", () {
      var mapper = SimpleDocumentMapper();
      mapper.registerEntityConverter(_BConverter());

      var b = mapper
          .convert<_B, Document>(Document.createDocument("value", "test"));
      expect(b, isNotNull);
      expect(b?.value, "test");
    });

    test("Test Convert Entity To Document with EntityConverter", () {
      var mapper = SimpleDocumentMapper();
      mapper.registerEntityConverter(_BConverter());

      var b = _B("test");
      var document = mapper.convert<Document, _B>(b);
      expect(document, isNotNull);
      expect(document?.get("value"), "test");
    });
  });
}

class _A {
  final String value;
  _A(this.value);
}

class _B {
  String? value;
  _B([this.value]);
}

class _BConverter extends EntityConverter<_B> {
  @override
  _B fromDocument(Document document, NitriteMapper nitriteMapper) {
    return _B(document["value"] as String);
  }

  @override
  Document toDocument(_B entity, NitriteMapper nitriteMapper) {
    return Document.createDocument("value", entity.value);
  }
}
