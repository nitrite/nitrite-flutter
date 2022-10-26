import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/converter_writer.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

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
    });
  });
}

@Converter()
class A {
  final String field;

  A([this.field = "a"]);
}

@Converter(className: 'MyBConverter')
class B {
  final String field;

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

  @Property(alias: 'secondField')
  String get field2 => _field2;

  @Property(alias: 'firstField')
  void set field1(String value) => this._field1 = value;

  @Property(alias: 'secondField')
  void set field2(String value) => this._field2 = value;
}
