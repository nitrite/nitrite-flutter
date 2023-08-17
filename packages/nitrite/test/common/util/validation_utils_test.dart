import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group(retry: 3, "ValidationUtils Test Suite", () {
    test("Test ValidateIterableIndexField", () {
      List<dynamic> iterable = [1, 2, 3, 4];
      try {
        validateIterableIndexField(iterable, "iter");
      } catch (e) {
        fail("validateIterableIndexField should not throw here");
      }

      iterable = [
        1,
        2,
        [1, 2],
        3
      ];
      expect(() => validateIterableIndexField(iterable, "iter"),
          throwsInvalidOperationException);

      iterable = [1, null];
      try {
        validateIterableIndexField(iterable, "iter");
      } catch (e) {
        fail("validateIterableIndexField should not throw here");
      }

      iterable = [1, 2, 3, SpatialKey(1, [])];
      expect(() => validateIterableIndexField(iterable, "iter"),
          throwsIndexingException);
    });

    test("Test ValidateArrayIndexItem", () {
      expect(() => validateArrayIndexItem([], "iter"),
          throwsInvalidOperationException);

      expect(() => validateArrayIndexItem(SpatialKey(1, []), "iter"),
          throwsIndexingException);
    });

    test("Test ValidateStringIterableIndexField", () {
      List<dynamic> iterable = [1, 2, 3, 4];

      expect(() => validateStringIterableIndexField(iterable, "iter"),
          throwsIndexingException);

      iterable = [
        "a",
        ["b"]
      ];
      expect(() => validateStringIterableIndexField(iterable, "iter"),
          throwsIndexingException);

      iterable = ["a", 'b'];
      try {
        validateStringIterableIndexField(iterable, "iter");
      } catch (e) {
        fail("validateStringIterableIndexField should not throw here");
      }
    });

    test("Test ValidateStringIterableItem", () {
      expect(
          () => validateStringIterableItem(1, "iter"), throwsIndexingException);

      expect(() => validateStringIterableItem([], "iter"),
          throwsIndexingException);

      try {
        validateStringIterableItem("iterable", "iter");
      } catch (e) {
        fail("validateStringIterableItem should not throw here");
      }
    });

    test("Test IsNullOrEmpty", () {
      expect(null.isNullOrEmpty, isTrue);
      expect("".isNullOrEmpty, isTrue);
      expect("a".isNullOrEmpty, isFalse);

      expect([].isNullOrEmpty, isTrue);
      expect([[]].isNullOrEmpty, isFalse);
      expect([1].isNullOrEmpty, isFalse);

      expect(<String, String>{}.isNullOrEmpty, isTrue);
      expect(<String, String>{"String": "a"}.isNullOrEmpty, isFalse);
      expect(DateTime.now().isNullOrEmpty, isFalse);
    });

    test("Test NotNullOrEmpty", () {
      expect(() => null.notNullOrEmpty("a"), throwsValidationException);
      expect(() => "".notNullOrEmpty("a"), throwsValidationException);
      expect(() => [].notNullOrEmpty("a"), throwsValidationException);
      expect(() => {}.notNullOrEmpty("a"), throwsValidationException);
      expect(() => <int, int>{}.notNullOrEmpty("a"), throwsValidationException);

      try {
        'a'.notNullOrEmpty("a");
        [[]].notNullOrEmpty("a");
        [1].notNullOrEmpty("a");
        <String, String>{"String": "a"}.notNullOrEmpty("a");
        DateTime.now().notNullOrEmpty("a");
      } catch (e) {
        fail("NotNullOrEmpty should not throw here");
      }
    });

    test("Test ValidateProjectionType", () {
      var nitriteMapper = SimpleNitriteMapper();
      nitriteMapper.registerEntityConverter(_AConverter());
      nitriteMapper.registerEntityConverter(_CConverter());

      validateProjectionType<_A>(nitriteMapper);

      expect(() => validateProjectionType<_C>(nitriteMapper),
          throwsValidationException);
      expect(() => validateProjectionType<String>(nitriteMapper),
          throwsValidationException);
      expect(() => validateProjectionType<num>(nitriteMapper),
          throwsValidationException);
      expect(() => validateProjectionType(nitriteMapper),
          throwsValidationException);
    });

    test("Test ValidateRepositoryType", () {
      var nitriteMapper = SimpleNitriteMapper();
      nitriteMapper.registerEntityConverter(_AConverter());
      nitriteMapper.registerEntityConverter(_CConverter());

      validateRepositoryType<_A>(nitriteMapper);

      expect(() => validateRepositoryType<_C>(nitriteMapper),
          throwsValidationException);
      expect(() => validateRepositoryType<String>(nitriteMapper),
          throwsValidationException);
      expect(() => validateRepositoryType<num>(nitriteMapper),
          throwsValidationException);
      expect(() => validateRepositoryType(nitriteMapper),
          throwsValidationException);
    });
  });
}

class _A {
  final String? s;
  final int? i;
  final double? d;

  _A(this.s, this.i, this.d);
}

class _AConverter extends EntityConverter<_A> {
  @override
  _A fromDocument(Document document, NitriteMapper nitriteMapper) {
    return _A(document.get("s"), document.get("i"), document.get("d"));
  }

  @override
  Document toDocument(_A entity, NitriteMapper nitriteMapper) {
    return emptyDocument()
        .put("s", entity.s)
        .put("i", entity.i)
        .put("d", entity.d);
  }
}

class _C {}

class _CConverter extends EntityConverter<_C> {
  @override
  _C fromDocument(Document document, NitriteMapper nitriteMapper) {
    return _C();
  }

  @override
  Document toDocument(_C entity, NitriteMapper nitriteMapper) {
    return emptyDocument();
  }
}
