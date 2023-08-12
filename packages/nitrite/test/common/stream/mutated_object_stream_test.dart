import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/mutated_object_stream.dart';
import 'package:test/test.dart';

void main() {
  group("MutatedObjectStream Test Suite", () {
    test("Test Mutate with Id Strip", () async {
      var nitriteMapper = EntityConverterMapper();
      nitriteMapper.registerEntityConverter(_AConverter());

      var stream = MutatedObjectStream<_A>(
          Stream.fromIterable([
            documentFromMap({"_id": 1, "name": "John", "age": 20}),
            documentFromMap({"_id": 2, "name": "Jane", "age": 21}),
            documentFromMap({"_id": 3, "name": "Joe", "age": 22}),
          ]),
          nitriteMapper);

      var objectList = await stream.toList();
      expect(objectList.length, 3);
      expect(objectList, [
        _A("John", 20),
        _A("Jane", 21),
        _A("Joe", 22),
      ]);
      expect(objectList[0].id, isNull);
    });

    test("Test Mutate without Id Strip", () async {
      var nitriteMapper = EntityConverterMapper();
      nitriteMapper.registerEntityConverter(_AConverter());

      var stream = MutatedObjectStream<_A>(
          Stream.fromIterable([
            documentFromMap({"_id": 1, "name": "John", "age": 20}),
            documentFromMap({"_id": 2, "name": "Jane", "age": 21}),
            documentFromMap({"_id": 3, "name": "Joe", "age": 22}),
          ]),
          nitriteMapper,
          false);

      var objectList = await stream.toList();
      expect(objectList.length, 3);
      expect(objectList, [
        _A("John", 20),
        _A("Jane", 21),
        _A("Joe", 22),
      ]);
      expect(objectList[0].id, isNotNull);
    });
  });
}

class _A {
  int? id;
  String? name;
  int? age;

  _A([this.name, this.age]);

  @override
  String toString() => "name: $name, age: $age";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _A &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

class _AConverter extends EntityConverter<_A> {
  @override
  _A fromDocument(Document document, NitriteMapper nitriteMapper) {
    _A entity = _A();
    entity.id = document.get("_id");
    entity.name = document.get("name");
    entity.age = document.get("age");
    return entity;
  }

  @override
  Document toDocument(_A entity, NitriteMapper nitriteMapper) {
    return documentFromMap({
      "_id": entity.id,
      "name": entity.name,
      "age": entity.age,
    });
  }
}