import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:faker/faker.dart';
import 'package:nitrite/nitrite.dart';

part 'test_data.no2.dart';

var random = Random(DateTime.now().millisecondsSinceEpoch);
var faker = Faker(seed: DateTime.now().millisecondsSinceEpoch);

@Entity(indices: [
  Index(fields: ["joinDate"], type: IndexType.nonUnique),
  Index(fields: ["address"], type: IndexType.fullText),
  Index(fields: ["employeeNote.text"], type: IndexType.fullText),
])
@Convertable()
class Employee with _$EmployeeEntityMixin {
  @Id(fieldName: 'empId')
  int? empId;
  DateTime? joinDate;
  String address;
  String emailAddress;
  List<int> blob;
  @IgnoredKey()
  Company? company;
  Note? employeeNote;

  static Employee clone(Employee employee) {
    return Employee(
        address: employee.address,
        blob: employee.blob,
        company: employee.company,
        emailAddress: employee.emailAddress,
        empId: employee.empId,
        joinDate: employee.joinDate,
        employeeNote: employee.employeeNote);
  }

  Employee({
    this.empId,
    this.joinDate,
    this.address = '',
    this.emailAddress = '',
    this.blob = const [],
    this.company,
    this.employeeNote,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          empId == other.empId &&
          joinDate == other.joinDate &&
          address == other.address &&
          emailAddress == other.emailAddress &&
          ListEquality().equals(blob, other.blob) &&
          company == other.company &&
          employeeNote == other.employeeNote;

  @override
  int get hashCode =>
      empId.hashCode ^
      joinDate.hashCode ^
      address.hashCode ^
      emailAddress.hashCode ^
      blob.hashCode ^
      company.hashCode ^
      employeeNote.hashCode;

  @override
  String toString() {
    return "{empId: $empId, joinDate: $joinDate, address: $address, "
        "emailAddress: $emailAddress, blob: $blob, company: $company, "
        "employeeNote: $employeeNote}";
  }
}

@Entity(indices: [
  Index(fields: ['companyName'])
])
class Company with _$CompanyEntityMixin {
  @Id(fieldName: 'company_id')
  @DocumentKey(alias: 'company_id')
  final int companyId;
  final String companyName;
  final DateTime? dateCreated;
  final List<String> departments;
  final Map<String, List<Employee>> employeeRecord;

  Company({
    this.companyId = 0,
    this.companyName = '',
    this.dateCreated,
    this.departments = const [],
    this.employeeRecord = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Company &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          companyName == other.companyName &&
          dateCreated == other.dateCreated &&
          ListEquality().equals(departments, other.departments) &&
          MapEquality<String, List<Employee>>()
              .equals(employeeRecord, other.employeeRecord);

  @override
  int get hashCode =>
      companyId.hashCode ^
      companyName.hashCode ^
      dateCreated.hashCode ^
      departments.hashCode ^
      employeeRecord.hashCode;
}

@Convertable()
class Note {
  final int noteId;
  final String text;

  Note({
    this.noteId = 0,
    this.text = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          noteId == other.noteId &&
          text == other.text;

  @override
  int get hashCode => noteId.hashCode ^ text.hashCode;

  @override
  String toString() {
    return 'Note{noteId: $noteId, text: $text}';
  }
}

class CompanyConverter extends EntityConverter<Company> {
  @override
  Company fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var map = <String, List<Employee>>{};
    var employeeRecords = document['employeeRecord'] == null
        ? {}
        : document['employeeRecord'] as Map;

    for (var entry in employeeRecords.entries) {
      var key = nitriteMapper.tryConvert<String, dynamic>(entry.key);
      var value = EntityConverter.toList<Employee>(entry.value, nitriteMapper);
      map[key] = value;
    }

    var entity = Company(
      companyId: document['company_id'] ?? 0,
      companyName: document['companyName'] ?? "",
      dateCreated: document['dateCreated'],
      departments:
          EntityConverter.toList(document['departments'], nitriteMapper),
      employeeRecord: map,
    );

    return entity;
  }

  @override
  Document toDocument(
    Company entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('company_id', entity.companyId);
    document.put('companyName', entity.companyName);
    document.put('dateCreated', entity.dateCreated);
    document.put('departments',
        EntityConverter.fromList(entity.departments, nitriteMapper));
    document.put('employeeRecord',
        EntityConverter.fromMap(entity.employeeRecord, nitriteMapper));
    return document;
  }
}

Company generateCompanyRecord() {
  var departments = generateDepartments();
  var company = Company(
      companyId: DateTime.now().millisecondsSinceEpoch,
      companyName: faker.guid.guid(),
      dateCreated: faker.date.dateTime(),
      departments: departments,
      employeeRecord: {});

  setEmployeeRecords(company, departments);
  return company;
}

List<String> generateDepartments() {
  return [
    'dev',
    'hr',
    'qa',
    'dev-ops',
    'sales',
    'marketing',
    'design',
    'support',
  ];
}

void setEmployeeRecords(Company company, List<String> departments) {
  for (var value in departments) {
    company.employeeRecord[value] =
        generateEmployeeRecords(company, random.nextInt(20)).toList();
  }
}

Iterable<Employee> generateEmployeeRecords(Company company, int nextInt) sync* {
  for (var i = 0; i < nextInt; i++) {
    yield generateEmployee(company);
  }
}

Employee generateEmployee(Company? company) {
  return Employee(
      empId: DateTime.now().millisecondsSinceEpoch,
      joinDate: faker.date.dateTime(),
      address: faker.address.streetAddress(),
      emailAddress: faker.internet.email(),
      blob: utf8.encode(faker.lorem.sentence()),
      company: company,
      employeeNote: generateNote());
}

Note generateNote() {
  return Note(
    noteId: DateTime.now().millisecondsSinceEpoch,
    text: faker.lorem.sentences(random.nextInt(10)).join('. '),
  );
}
