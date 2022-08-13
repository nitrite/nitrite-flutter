import 'package:collection/collection.dart';
import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/common/mapper/mappable_mapper.dart';
import 'package:nitrite/src/common/mapper/nitrite_mapper.dart';
import 'package:test/test.dart';

void main() {
  group("Mapper Test Suite", () {
    test("Test With Converter", () {
      var boss = _Employee();
      boss.empId = "1";
      boss.name = "Boss";
      boss.joiningDate = DateTime.now();

      var emp = _Employee();
      emp.empId = "2";
      emp.name = "Emp";
      emp.joiningDate = DateTime.now();
      emp.boss = boss;

      var mapper = MappableMapper();
      mapper.registerMappable(() => _Employee());
      var stopWatch = Stopwatch();
      stopWatch.start();
      var doc = mapper.convert<Document, _Employee>(emp);
      stopWatch.stop();
      expect(doc, isNotNull);
      print("Time Taken: ${stopWatch.elapsedMilliseconds}");

      stopWatch.start();
      var emp2 = mapper.convert<_Employee, Document>(doc);
      stopWatch.stop();
      print("Time Taken: ${stopWatch.elapsedMilliseconds}");
      expect(emp2, emp);
    });

    test("Test Nested", () {
      var boss = _Employee();
      boss.empId = "1";
      boss.name = "Boss";
      boss.joiningDate = DateTime.now();

      var emp = _Employee();
      emp.empId = "2";
      emp.name = "Emp";
      emp.joiningDate = DateTime.now();
      emp.boss = boss;

      var dept = _Department();
      dept.name = "Dept";
      dept.employees.add(emp);
      dept.employees.add(boss);

      var mapper = MappableMapper();
      mapper.registerMappable(() => _Employee());
      mapper.registerMappable(() => _Department());

      var stopWatch = Stopwatch();
      stopWatch.start();
      var doc = mapper.convert<Document, _Department>(dept);
      stopWatch.stop();
      expect(doc, isNotNull);
      print("Time Taken: ${stopWatch.elapsedMilliseconds}");

      stopWatch.start();
      var dept2 = mapper.convert<_Department, Document>(doc);
      stopWatch.stop();
      print("Time Taken: ${stopWatch.elapsedMilliseconds}");
      expect(dept2, dept);
    });
  });
}

class _Employee implements Mappable {
  String? empId;
  String? name;
  DateTime? joiningDate;
  _Employee? boss;

  @override
  void read(NitriteMapper? mapper, Document document) {
    empId = document.get('empId');
    name = document.get('name');
    joiningDate = document.get('joiningDate');
    if (document.containsKey('boss') && document.get('boss') != null) {
      boss = _Employee();
      boss?.read(mapper, document.get("boss"));
    }
  }

  @override
  Document write(NitriteMapper? mapper) {
    var document = Document.emptyDocument();
    document.put('empId', empId);
    document.put('name', name);
    document.put('joiningDate', joiningDate);
    document.put('boss', boss?.write(mapper));
    return document;
  }

  @override
  operator ==(Object? other) =>
      identical(this, other) ||
      other is _Employee &&
          runtimeType == other.runtimeType &&
          empId == other.empId &&
          name == other.name &&
          joiningDate == other.joiningDate &&
          boss == other.boss;

  @override
  int get hashCode =>
      empId.hashCode ^ name.hashCode ^ joiningDate.hashCode ^ boss.hashCode;
}

class _Department implements Mappable {
  String? name;
  List<_Employee> employees = [];

  @override
  void read(NitriteMapper? mapper, Document document) {
    name = document.get('name');
    if (document.containsKey('employees') &&
        document.get('employees') != null) {
      var docs = document.get('employees') as List<Document>;
      for (var doc in docs) {
        var emp = _Employee();
        emp.read(mapper, doc);
        employees.add(emp);
      }
    }
  }

  @override
  Document write(NitriteMapper? mapper) {
    var document = Document.emptyDocument();
    document.put('name', name);
    var docs = employees.map((emp) => emp.write(mapper)).toList();
    document.put('employees', docs);
    return document;
  }

  @override
  operator ==(Object? other) =>
      identical(this, other) ||
      other is _Department &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          ListEquality().equals(employees, other.employees);

  @override
  int get hashCode => name.hashCode ^ ListEquality().hash(employees);
}
