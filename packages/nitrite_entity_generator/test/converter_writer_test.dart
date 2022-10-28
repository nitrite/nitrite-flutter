import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/converter_writer.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

part 'converter_writer_test.no2.dart';

void main() {
  group("Converter Writer Test Suite", () {
    test("Test Converter Class Name", () async {
      final converterInfo = await createConverterInfo('''
        @Converter(className: 'MyCustomConverter')
        class Customer {
          final String stringName;
          
          Customer({this.stringName});
        }   
      ''');

      var actual = ConverterWriter(converterInfo).write();

      expect(actual.name, 'MyCustomConverter');
    });

    test("All Valid Converters", () {
      var nitriteMapper = SimpleDocumentMapper();
      nitriteMapper.registerEntityConverter(AConverter());
      nitriteMapper.registerEntityConverter(MyBConverter());
      nitriteMapper.registerEntityConverter(CConverter());
      nitriteMapper.registerEntityConverter(DConverter());
      nitriteMapper.registerEntityConverter(EConverter());
      nitriteMapper.registerEntityConverter(FConverter());
      nitriteMapper.registerEntityConverter(GConverter());
      nitriteMapper.registerEntityConverter(HConverter());

      var a = A('test');
      Document doc = nitriteMapper.convert<Document, A>(a);
      var a2 = nitriteMapper.convert<A, Document>(doc);
      expect(a.field, a2.field);

      var b = B('test');
      doc = nitriteMapper.convert<Document, B>(b);
      var b2 = nitriteMapper.convert<B, Document>(doc);
      expect(b.field, b2.field);

      var c = C(field1: "a", field2: "b");
      doc = nitriteMapper.convert<Document, C>(c);
      var c2 = nitriteMapper.convert<C, Document>(doc);
      expect(c.field1, c2.field1);
      expect(c.field2, c2.field2);

      var d = D(field1: "a", field2: "b");
      doc = nitriteMapper.convert<Document, D>(d);
      var d2 = nitriteMapper.convert<D, Document>(doc);
      expect(d.field1, d2.field1);
      expect(d.field2, d2.field2);

      var e = E();
      e.field1 = "e";
      e.field2 = null;
      doc = nitriteMapper.convert<Document, E>(e);
      var e2 = nitriteMapper.convert<E, Document>(doc);
      expect(e.field1, e2.field1);
      expect(e.field2, e2.field2);

      var f = F("f");
      doc = nitriteMapper.convert<Document, F>(f);
      var f2 = nitriteMapper.convert<F, Document>(doc);
      expect(f.field1, f2.field1);
      expect(f.field2, f2.field2);

      var g = G("g1", "g2");
      doc = nitriteMapper.convert<Document, G>(g);
      var g2 = nitriteMapper.convert<G, Document>(doc);
      expect(g.field1, g2.field1);
      expect(g.field2, g2.field2);

      var h = H("h1", "h2");
      doc = nitriteMapper.convert<Document, H>(h);
      var h2 = nitriteMapper.convert<H, Document>(doc);
      expect(h.field1, h2.field1);
      expect(h.field2, 'h2');
      expect(h2.field2, isEmpty);
    });
  });
}

@GenerateConverter()
class A {
  String field;

  A([this.field = "a"]);
}

@GenerateConverter(className: 'MyBConverter')
class B {
  String field;

  B([this.field = "a"]);
}

@GenerateConverter()
class C {
  final String field1;
  final String field2;

  C({this.field1 = "", this.field2 = ""});
}

@GenerateConverter()
class D {
  String? field1;
  String? field2;

  D({this.field1 = "", this.field2 = ""});
}

@GenerateConverter()
class E {
  String? field1;
  String? field2;
}

@GenerateConverter()
class F {
  String? field1;
  String? field2;

  F([this.field1 = "", this.field2 = ""]);
}

@GenerateConverter()
class G {
  String _field1;
  String _field2;

  G([this._field1 = "", this._field2 = ""]);

  @DocumentKey(alias: 'firstField')
  String get field1 => _field1;

  String get field2 => _field2;

  @DocumentKey(alias: 'firstField')
  void set field1(String value) => this._field1 = value;

  void set field2(String value) => this._field2 = value;
}

@GenerateConverter()
class H {
  String _field1;
  String _field2;

  H([this._field1 = "", this._field2 = ""]);

  @DocumentKey(alias: 'firstField')
  String get field1 => _field1;

  @IgnoredKey()
  String get field2 => _field2;

  @DocumentKey(alias: 'firstField')
  void set field1(String value) => this._field1 = value;

  @IgnoredKey()
  void set field2(String value) => this._field2 = value;
}