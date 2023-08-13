import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group(retry: 3, 'SimpleDocumentMapper Test Suite', () {
    test('Test Convert Value Type', () {
      var mapper = EntityConverterMapper();
      {
        var value = mapper.tryConvert<int, int>(1);
        expect(value, 1);
      }

      {
        var value = mapper.tryConvert<double, double>(1.0);
        expect(value, 1.0);
      }

      {
        var value = mapper.tryConvert<String, String>('1');
        expect(value, '1');
      }

      {
        var value = mapper.tryConvert<bool, bool>(true);
        expect(value, true);
      }

      {
        var value = mapper.tryConvert<void, void>(null);
        expect(value, null);
      }

      {
        var value = mapper.tryConvert<DateTime, DateTime>(DateTime(2020, 1, 1));
        expect(value, DateTime(2020, 1, 1));
      }

      {
        var value = mapper.tryConvert<Duration, Duration>(Duration(days: 1));
        expect(value, Duration(days: 1));
      }

      {
        var value =
            mapper.tryConvert<NitriteId, NitriteId>(NitriteId.createId('1'));
        expect(value, NitriteId.createId('1'));
      }
    });

    test('Test Convert From Document', () {
      var mapper = EntityConverterMapper();
      {
        var value = mapper
            .tryConvert<Document, Document>(createDocument("key", "value"));
        expect(value, createDocument("key", "value"));
      }
    });

    test("Test Convert To Document without EntityConverter", () {
      var mapper = EntityConverterMapper();
      var a = _A("test");
      expect(() => mapper.tryConvert<Document, _A>(a),
          throwsObjectMappingException);
    });

    test("Test Convert Document To Entity without EntityConverter", () {
      var mapper = EntityConverterMapper();
      expect(
          () => mapper.tryConvert<_A, Document>(createDocument("key", "value")),
          throwsObjectMappingException);
    });

    test("Test Convert Document To Entity with EntityConverter", () {
      var mapper = EntityConverterMapper();
      mapper.registerEntityConverter(_BConverter());

      var b = mapper.tryConvert<_B, Document>(createDocument("value", "test"));
      expect(b, isNotNull);
      expect(b?.value, "test");
    });

    test("Test Convert Entity To Document with EntityConverter", () {
      var mapper = EntityConverterMapper();
      mapper.registerEntityConverter(_BConverter());

      var b = _B("test");
      var document = mapper.tryConvert<Document, _B>(b);
      expect(document, isNotNull);
      expect(document?.get("value"), "test");
    });

    test("Test Convert Nullable Entity", () {
      var mapper = EntityConverterMapper();
      mapper.registerEntityConverter(_BConverter());

      var b = _B("test");
      var document = mapper.tryConvert<Document, _B?>(b);
      expect(document, isNotNull);
      expect(document?.get("value"), "test");

      var bb = mapper.tryConvert<_B?, Document>(document);
      expect(bb, isNotNull);
      expect(bb?.value, "test");
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
    return createDocument("value", entity.value);
  }
}
