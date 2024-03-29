import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

part 'mapper_test.no2.dart';

void main() {
  group(retry: 3, "Mapper Test Suite", () {
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

      var mapper = SimpleNitriteMapper();
      mapper.registerEntityConverter(_EmployeeConverter());
      var stopWatch = Stopwatch();
      stopWatch.start();
      var doc = mapper.tryConvert<Document, _Employee>(emp);
      stopWatch.stop();
      expect(doc, isNotNull);

      stopWatch.start();
      var emp2 = mapper.tryConvert<_Employee, Document>(doc);
      stopWatch.stop();
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

      var mapper = SimpleNitriteMapper();
      mapper.registerEntityConverter(_EmployeeConverter());
      mapper.registerEntityConverter(_DepartmentConverter());

      var stopWatch = Stopwatch();
      stopWatch.start();
      var doc = mapper.tryConvert<Document, _Department>(dept);
      stopWatch.stop();
      expect(doc, isNotNull);

      stopWatch.start();
      var dept2 = mapper.tryConvert<_Department, Document>(doc);
      stopWatch.stop();
      expect(dept2, dept);
    });
  });
}

@Convertable()
class _Employee {
  String? empId;
  String? name;
  DateTime? joiningDate;
  _Employee? boss;

  @override
  operator ==(Object other) =>
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

@Convertable()
class _Department {
  String? name;
  List<_Employee> employees = [];

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is _Department &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          ListEquality().equals(employees, other.employees);

  @override
  int get hashCode => name.hashCode ^ ListEquality().hash(employees);
}
