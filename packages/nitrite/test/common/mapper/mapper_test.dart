import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
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

      var mapper = SimpleDocumentMapper();
      mapper.registerEntityConverter(_EmployeeConverter());
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

      var mapper = SimpleDocumentMapper();
      mapper.registerEntityConverter(_EmployeeConverter());
      mapper.registerEntityConverter(_DepartmentConverter());

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

class _Employee {
  String? empId;
  String? name;
  DateTime? joiningDate;
  _Employee? boss;

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

class _EmployeeConverter extends EntityConverter<_Employee> {
  @override
  _Employee fromDocument(Document document, NitriteMapper nitriteMapper) {
    _Employee entity = _Employee();
    entity.empId = document.get('empId');
    entity.name = document.get('name');
    entity.joiningDate = document.get('joiningDate');
    if (document.containsKey('boss') && document.get('boss') != null) {
      entity.boss =
          nitriteMapper.convert<_Employee, Document>(document.get("boss"));
    }
    return entity;
  }

  @override
  Document toDocument(_Employee entity, NitriteMapper nitriteMapper) {
    var document = Document.emptyDocument();
    document.put('empId', entity.empId);
    document.put('name', entity.name);
    document.put('joiningDate', entity.joiningDate);
    document.put(
        'boss', nitriteMapper.convert<Document, _Employee>(entity.boss));
    return document;
  }
}

class _Department {
  String? name;
  List<_Employee> employees = [];

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

class _DepartmentConverter extends EntityConverter<_Department> {
  @override
  _Department fromDocument(Document document, NitriteMapper nitriteMapper) {
    _Department entity = _Department();
    entity.name = document.get('name');
    if (document.containsKey('employees') &&
        document.get('employees') != null) {
      var docs = document.get('employees') as List<Document?>;
      for (var doc in docs) {
        var emp = nitriteMapper.convert<_Employee, Document>(doc);
        if (emp != null) {
          entity.employees.add(emp);
        }
      }
    }
    return entity;
  }

  @override
  Document toDocument(_Department entity, NitriteMapper nitriteMapper) {
    var document = Document.emptyDocument();
    document.put('name', entity.name);
    var docs = entity.employees
        .map((emp) => nitriteMapper.convert<Document, _Employee>(emp))
        .toList();
    document.put('employees', docs);
    return document;
  }
}
