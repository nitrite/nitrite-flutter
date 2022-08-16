import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/mapper/mappable_mapper.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

part 'object_utils_test.no2.dart';

void main() {
  group("Object Utils Test Suite", () {
    test('Test BlackHole', () {
      var stream = Stream.fromIterable([1, 2, 3]);
      stream.listen(blackHole);

      expect(() => stream.listen(blackHole), throwsStateError);
    });

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

      var b = _B();
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

      var c = _C();
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
      var nitriteMapper = MappableMapper();
      nitriteMapper.registerMappable(() => _F());
      nitriteMapper.registerMappable(() => _G());

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
      var nitriteMapper = MappableMapper();
      nitriteMapper.registerMappable(() => _F());
      nitriteMapper.registerMappable(() => _G());

      expect(getEntityName<_F>(nitriteMapper), '_F');
      expect(getEntityName<_G>(nitriteMapper), 'g');
      expect(getEntityName(nitriteMapper), 'dynamic');
      expect(getEntityName<DateTime>(nitriteMapper), 'DateTime');
    });
  });
}

abstract class _A {}

class _B extends _A {}

class _C extends _B {}

mixin _M {}

class _D with _M {}

class _E implements _A {}

class _F implements Mappable {
  @override
  void read(NitriteMapper? mapper, Document document) {}

  @override
  Document write(NitriteMapper? mapper) {
    return emptyDocument();
  }
}

@Entity(name: 'g')
class _G with _$_GEntityMixin implements Mappable {
  @override
  void read(NitriteMapper? mapper, Document document) {}

  @override
  Document write(NitriteMapper? mapper) {
    return emptyDocument();
  }
}
