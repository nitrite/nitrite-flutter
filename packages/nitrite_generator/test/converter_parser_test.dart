import 'package:nitrite_generator/src/converter_parser.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group(retry: 3, "Converter Parser Suite", () {
    test('Parse Ctor with All Required Params', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          String name;
          int age;
          String location;
          
          Customer(this.name, this.age, this.location);
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Ctor with All Required final Params', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer(this.name, this.age, this.location);
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Constant Ctor with All Required final Params', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          const Customer(this.name, this.age, this.location);
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Redirecting Ctor', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer(this.name, this.age, this.location);
          
          Customer.empty() : this("", 0, "");
          
          Customer.withoutLocation(String name, int age) : this(name, age, "")
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Named Ctor', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer.empty() {
            name = "";
            age = 0;
            location = "";
          }
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Factory Ctor', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer.empty() {
            name = "";
            age = 0;
            location = "";
          }
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Ctor with Some Positional Optional Param', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          int? age;
          String? location;
          
          Customer(this.name, [this.age, this.location]);
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Ctor with Some Named Optional Param', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          int? age;
          String? location;
          
          Customer(this.name, {this.age, this.location});
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Ctor with Some Positional Optional Param with Default Value',
        () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          int? age;
          String? location;
          
          Customer(this.name, [this.age, this.location = "US"]);
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse private Ctor', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          String? name;
          int? age;
          String? location;
          
          Customer._();
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Ctor with All Positional Optional Params with Default Value',
        () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer([this.name = "", this.age = 0, this.location = ""]);
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test("Ignored Field with Non Nullable Type", () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          @IgnoredKey()
          String name;
          int number;
        
          Customer({required this.name, required this.number});
        }
      ''');

      expect(() => ConverterParser(classElement).parse(),
          throwsA(TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('Parse Default Ctor', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          String? name;
          int? age;
          String? location;
        }
      ''');

      var converterInfo = ConverterParser(classElement).parse();
      expect(converterInfo, isNotNull);
      expect(converterInfo.constructorInfo, isNotNull);
      expect(converterInfo.constructorInfo.hasDefaultCtor, isTrue);
      expect(converterInfo.constructorInfo.hasAllOptionalNamedCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllNamedCtor, isFalse);
      expect(
          converterInfo.constructorInfo.hasAllOptionalPositionalCtor, isFalse);
      expect(converterInfo.className, 'Customer');
      expect(converterInfo.fieldInfoList, isNotEmpty);
      expect(converterInfo.fieldInfoList.length, 3);
      expect(converterInfo.fieldInfoList.where((f) => f.isFinal).length, 0);
    });

    test('Parse Ctor with All Named Optional Params', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          String? name;
          int? age;
          String? location;
          
          Customer({this.name, this.age, this.location});
        }
      ''');

      var converterInfo = ConverterParser(classElement).parse();
      expect(converterInfo, isNotNull);
      expect(converterInfo.constructorInfo, isNotNull);
      expect(converterInfo.constructorInfo.hasDefaultCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllOptionalNamedCtor, isTrue);
      expect(converterInfo.constructorInfo.hasAllNamedCtor, isTrue);
      expect(
          converterInfo.constructorInfo.hasAllOptionalPositionalCtor, isFalse);
      expect(converterInfo.className, 'Customer');
      expect(converterInfo.fieldInfoList, isNotEmpty);
      expect(converterInfo.fieldInfoList.length, 3);
      expect(converterInfo.fieldInfoList.where((f) => f.isFinal).length, 0);
    });

    test('Parse Ctor with All Positional Optional Params', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          String? name;
          int? age;
          String? location;
          
          Customer([this.name, this.age, this.location]);
        }
      ''');

      var converterInfo = ConverterParser(classElement).parse();
      expect(converterInfo, isNotNull);
      expect(converterInfo.constructorInfo, isNotNull);
      expect(converterInfo.constructorInfo.hasDefaultCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllOptionalNamedCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllNamedCtor, isFalse);
      expect(
          converterInfo.constructorInfo.hasAllOptionalPositionalCtor, isTrue);
      expect(converterInfo.className, 'Customer');
      expect(converterInfo.fieldInfoList, isNotEmpty);
      expect(converterInfo.fieldInfoList.length, 3);
      expect(converterInfo.fieldInfoList.where((f) => f.isFinal).length, 0);
    });

    test('Parse Ctor with All Named Optional Params with Default Value',
        () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer({this.name = "", this.age = 0, this.location = ""});
        }
      ''');

      var converterInfo = ConverterParser(classElement).parse();
      expect(converterInfo, isNotNull);
      expect(converterInfo.constructorInfo, isNotNull);
      expect(converterInfo.constructorInfo.hasDefaultCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllOptionalNamedCtor, isTrue);
      expect(converterInfo.constructorInfo.hasAllNamedCtor, isTrue);
      expect(
          converterInfo.constructorInfo.hasAllOptionalPositionalCtor, isFalse);
      expect(converterInfo.className, 'Customer');
      expect(converterInfo.fieldInfoList, isNotEmpty);
      expect(converterInfo.fieldInfoList.length, 3);
      expect(converterInfo.fieldInfoList.where((f) => f.isFinal).length, 3);
    });

    test('Parse Ctor with All Named Params', () async {
      final classElement = await createClassElement('''
        @Convertable()
        class Customer {
          final String name;
          final int age;
          final String location;
          
          Customer({required this.name, required this.age, required this.location});
        }
      ''');

      var converterInfo = ConverterParser(classElement).parse();
      expect(converterInfo, isNotNull);
      expect(converterInfo.constructorInfo, isNotNull);
      expect(converterInfo.constructorInfo.hasDefaultCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllOptionalNamedCtor, isFalse);
      expect(converterInfo.constructorInfo.hasAllNamedCtor, isTrue);
      expect(
          converterInfo.constructorInfo.hasAllOptionalPositionalCtor, isFalse);
      expect(converterInfo.className, 'Customer');
      expect(converterInfo.fieldInfoList, isNotEmpty);
      expect(converterInfo.fieldInfoList.length, 3);
      expect(converterInfo.fieldInfoList.where((f) => f.isFinal).length, 3);
    });
  });
}
