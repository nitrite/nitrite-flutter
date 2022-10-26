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

      var a = A('test');
      Document doc = nitriteMapper.convert<Document, A>(a);
      var a2 = nitriteMapper.convert<A, Document>(doc);
      expect(a.field, a2.field);
    });
  });
}

@Converter()
class A {
  String field;

  A([this.field = "a"]);
}

@Converter(className: 'MyBConverter')
class B {
  String field;

  B([this.field = "a"]);
}

@Converter()
class C {
  final String field1;
  final String field2;

  C({this.field1 = "", this.field2 = ""});
}

@Converter()
class D {
  String? field1;
  String? field2;

  D({this.field1 = "", this.field2 = ""});
}

@Converter()
class E {
  String? field1;
  String? field2;
}

@Converter()
class F {
  String? field1;
  String? field2;

  F([this.field1 = "", this.field2 = ""]);
}

@Converter()
class G {
  String _field1;
  String _field2;

  G([this._field1 = "", this._field2 = ""]);

  @Property(alias: 'firstField')
  String get field1 => _field1;

  String get field2 => _field2;

  @Property(alias: 'firstField')
  void set field1(String value) => this._field1 = value;

  void set field2(String value) => this._field2 = value;
}
