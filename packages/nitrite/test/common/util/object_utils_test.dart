import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:quiver/pattern.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

part 'object_utils_test.no2.dart';

void main() {
  group("Object Utils Test Suite", () {
    test('Test IsSubtype', () {
      expect(isSubtype<int, num>(), isTrue);
      expect(isSubtype<num, int>(), isFalse);
      expect(isSubtype<int, int>(), isTrue);
      expect(isSubtype<int, double>(), isFalse);

      expect(isSubtype<bool, String>(), isFalse);
      expect(isSubtype<String, Object>(), isTrue);

      expect(isSubtype<int, dynamic>(), isTrue);

      expect(isSubtype<_B, _A>(), isTrue);
      expect(isSubtype<_C, _A>(), isTrue);
      expect(isSubtype<_C, _M>(), isFalse);
      expect(isSubtype<_D, _M>(), isTrue);
      expect(isSubtype<_E, _A>(), isTrue);
      expect(isSubtype<_D, _A>(), isFalse);
    });

    test('Test GetKeyName', () {
      expect(getKeyName('name+key'), 'key');
      expect(() => getKeyName('name'), throwsValidationException);
    });

    test('Test GetKeyedRepositoryType', () {
      expect(getKeyedRepositoryType('name+key'), 'name');
      expect(() => getKeyedRepositoryType('name'), throwsValidationException);
    });

    test('Test DeepEquals', () {
      expect(deepEquals(null, null), isTrue);
      expect(deepEquals(null, 1), isFalse);
      expect(deepEquals(1, null), isFalse);

      var b = _B("test");
      expect(deepEquals(b, b), isTrue);
      expect(deepEquals(1, 1), isTrue);
      expect(deepEquals(1, 2), isFalse);
      expect(deepEquals(2, 2.0), isFalse);
      expect(deepEquals(2.0, 2), isFalse);

      var array1 = [1, 2, 3];
      var array2 = [1, 2, 3];
      expect(deepEquals(array1, array2), isTrue);
      array2[2] = 4;
      expect(deepEquals(array1, array2), isFalse);

      var map1 = {'a': 1, 'b': 2};
      var map2 = {'a': 1, 'b': 2};
      expect(deepEquals(map1, map2), isTrue);
      map2['b'] = 3;
      expect(deepEquals(map1, map2), isFalse);

      var set1 = {1, 2, 3};
      var set2 = {1, 2, 3};
      expect(deepEquals(set1, set2), isTrue);
      set2.add(4);
      expect(deepEquals(set1, set2), isFalse);

      var string1 = 'a';
      var string2 = 'a';
      expect(deepEquals(string1, string2), isTrue);
      string2 = 'b';
      expect(deepEquals(string1, string2), isFalse);

      var date1 = DateTime.parse('2020-01-01');
      var date2 = DateTime.parse('2020-01-01');
      expect(deepEquals(date1, date2), isTrue);

      var c = _C("test");
      expect(deepEquals(c, b), isFalse);
    });

    test('Test Compare', () {
      var date1 = DateTime.parse('2020-01-01');
      var date2 = DateTime.parse('2020-01-01');
      expect(compare(date1, date2), 0);
      date2 = DateTime.parse('2020-01-02');
      expect(compare(date1, date2), -1);

      expect(compare(1, 2), -1);
      expect(compare(2, 1), 1);
      expect(compare(1, 1), 0);

      expect(compare('a', 'b'), -1);
      expect(compare('b', 'a'), 1);
      expect(compare('a', 'a'), 0);
    });

    test('Test FindRepositoryNameByType', () {
      var nitriteMapper = SimpleDocumentMapper();
      nitriteMapper.registerEntityConverter(_FConverter());
      nitriteMapper.registerEntityConverter(_GConverter());

      expect(findRepositoryNameByType<_F>(nitriteMapper), '_F');
      expect(findRepositoryNameByType<_F>(nitriteMapper, 'a'),
          '_F${keyObjSeparator}a');

      expect(findRepositoryNameByType<_G>(nitriteMapper), 'g');
      expect(findRepositoryNameByType<_G>(nitriteMapper, 'a'),
          'g${keyObjSeparator}a');
    });

    test('Test findRepositoryNameByTypeName', () {
      expect(findRepositoryNameByTypeName('_F', null), '_F');
      expect(findRepositoryNameByTypeName('_F', 'a'), '_F${keyObjSeparator}a');
    });

    test('Test GetEntityName', () {
      var nitriteMapper = SimpleDocumentMapper();
      nitriteMapper.registerEntityConverter(_FConverter());
      nitriteMapper.registerEntityConverter(_GConverter());

      expect(getEntityName<_F>(nitriteMapper), '_F');
      expect(getEntityName<_G>(nitriteMapper), 'g');
      expect(getEntityName(nitriteMapper), 'dynamic');
      expect(getEntityName<DateTime>(nitriteMapper), 'DateTime');
    });

    test('Test FindRepositoryNameByDecorator', () {
      expect(findRepositoryNameByDecorator(_BDecorator()), "_B");
      expect(findRepositoryNameByDecorator(_BDecorator(), "key"), "_B+key");
      expect(findRepositoryNameByDecorator(_CDecorator()), "c");
      expect(findRepositoryNameByDecorator(_CDecorator(), "key"), "c+key");
    });

    test('Test NewInstance', () {
      var nitriteMapper = SimpleDocumentMapper();
      nitriteMapper.addValueType<_B>();
      nitriteMapper.registerEntityConverter(_FConverter());

      var f = newInstance<_F>(nitriteMapper);
      expect(f, isNotNull);

      f = newInstance<_F?>(nitriteMapper);
      expect(f, isNotNull);

      var i = newInstance<num>(nitriteMapper);
      expect(i, 0);

      i = newInstance<int>(nitriteMapper);
      expect(i, 0);

      var d = newInstance<double>(nitriteMapper);
      expect(d, 0.0);

      var s = newInstance<String>(nitriteMapper);
      expect(s, isNull);

      var r = newInstance<Runes>(nitriteMapper);
      expect(r, isNull);

      var boolean = newInstance<bool>(nitriteMapper);
      expect(boolean, false);

      var n = newInstance<Null>(nitriteMapper);
      expect(n, isNull);

      var date = newInstance<DateTime>(nitriteMapper);
      expect(date, isNull);

      var duration = newInstance<Duration>(nitriteMapper);
      expect(duration, isNull);

      var symbol = newInstance<Symbol>(nitriteMapper);
      expect(symbol, isNull);

      var b = newInstance<_B>(nitriteMapper);
      expect(b, isNull);

      expect(() => newInstance(nitriteMapper), throwsObjectMappingException);
      expect(
          () => newInstance<_G>(nitriteMapper), throwsObjectMappingException);
    });

    test('Test DefaultValue', () {
      expect(defaultValue<num>(), 0);
      expect(defaultValue<int>(), 0);
      expect(defaultValue<double>(), 0.0);
      expect(defaultValue<bool>(), false);
      expect(defaultValue<Object>(), isNull);
      expect(defaultValue(), isNull);

      expect(defaultValue<num?>(), isNull);
      expect(defaultValue<int?>(), isNull);
      expect(defaultValue<double?>(), isNull);
      expect(defaultValue<bool?>(), isNull);
      expect(defaultValue<Object?>(), isNull);
      expect(defaultValue(), isNull);
    });

    test('Test IsBuiltInValueType', () {
      var nitriteMapper = SimpleDocumentMapper();
      nitriteMapper.addValueType<_B>();
      nitriteMapper.registerEntityConverter(_FConverter());

      expect(isBuiltInValueType<num>(), isTrue);
      expect(isBuiltInValueType<num?>(), isTrue);
      expect(isBuiltInValueType<int>(), isTrue);
      expect(isBuiltInValueType<int?>(), isTrue);
      expect(isBuiltInValueType<double>(), isTrue);
      expect(isBuiltInValueType<double?>(), isTrue);
      expect(isBuiltInValueType<String>(), isTrue);
      expect(isBuiltInValueType<String?>(), isTrue);
      expect(isBuiltInValueType<Runes>(), isTrue);
      expect(isBuiltInValueType<Runes?>(), isTrue);
      expect(isBuiltInValueType<bool>(), isTrue);
      expect(isBuiltInValueType<bool?>(), isTrue);
      expect(isBuiltInValueType<Null>(), isTrue);
      expect(isBuiltInValueType<DateTime>(), isTrue);
      expect(isBuiltInValueType<DateTime?>(), isTrue);
      expect(isBuiltInValueType<Duration>(), isTrue);
      expect(isBuiltInValueType<Duration?>(), isTrue);
      expect(isBuiltInValueType<Symbol>(), isTrue);
      expect(isBuiltInValueType<Symbol?>(), isTrue);

      expect(isBuiltInValueType<Glob>(), isFalse);
      expect(isBuiltInValueType<Glob?>(), isFalse);
      expect(isBuiltInValueType<_B>(), isFalse);
      expect(isBuiltInValueType<_B?>(), isFalse);
      expect(isBuiltInValueType<_F>(), isFalse);
      expect(isBuiltInValueType<_F?>(), isFalse);
    });
  });
}

abstract class _A {}

class _B extends _A {
  final String value;
  _B(this.value);
}

class _C extends _B {
  final String val;
  _C(this.val) : super(val);
}

mixin _M {}

class _D with _M {}

class _E implements _A {}

class _F {}

class _FConverter extends EntityConverter<_F> {
  @override
  _F fromDocument(Document document, NitriteMapper nitriteMapper) {
    return _F();
  }

  @override
  Document toDocument(_F entity, NitriteMapper nitriteMapper) {
    return emptyDocument();
  }
}

@Entity(name: 'g')
class _G with _$_GEntityMixin {}

class _GConverter extends EntityConverter<_G> {
  @override
  _G fromDocument(Document document, NitriteMapper nitriteMapper) {
    return _G();
  }

  @override
  Document toDocument(_G entity, NitriteMapper nitriteMapper) {
    return emptyDocument();
  }
}

class _BDecorator extends EntityDecorator<_B> {
  @override
  EntityId? get idField => EntityId("value");

  @override
  List<EntityIndex> get indexFields => [
        EntityIndex(["value"], IndexType.nonUnique)
      ];
}

class _CDecorator implements EntityDecorator<_C> {
  @override
  EntityId? get idField => null;

  @override
  List<EntityIndex> get indexFields => [];

  @override
  String get entityName => "c";

  @override
  Type get entityType => _C;
}
