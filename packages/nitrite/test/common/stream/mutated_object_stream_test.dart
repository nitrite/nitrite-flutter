import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/mapper/mappable_mapper.dart';
import 'package:nitrite/src/common/stream/mutated_object_stream.dart';
import 'package:test/test.dart';

void main() {
  group("MutatedObjectStream Test Suite", () {
    test("Test Mutate with Id Strip", () async {
      var nitriteMapper = MappableMapper();
      nitriteMapper.registerMappable(() => _A());

      var stream = MutatedObjectStream<_A>(
          Stream.fromIterable([
            Document.fromMap({"_id": 1, "name": "John", "age": 20}),
            Document.fromMap({"_id": 2, "name": "Jane", "age": 21}),
            Document.fromMap({"_id": 3, "name": "Joe", "age": 22}),
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
      var nitriteMapper = MappableMapper();
      nitriteMapper.registerMappable(() => _A());

      var stream = MutatedObjectStream<_A>(
          Stream.fromIterable([
            Document.fromMap({"_id": 1, "name": "John", "age": 20}),
            Document.fromMap({"_id": 2, "name": "Jane", "age": 21}),
            Document.fromMap({"_id": 3, "name": "Joe", "age": 22}),
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

class _A implements Mappable {
  int? id;
  String? name;
  int? age;

  _A([this.name, this.age]);

  @override
  void read(NitriteMapper? mapper, Document document) {
    id = document.get("_id");
    name = document.get("name");
    age = document.get("age");
  }

  @override
  Document write(NitriteMapper? mapper) {
    return Document.fromMap({
      "_id": id,
      "name": name,
      "age": age,
    });
  }

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
