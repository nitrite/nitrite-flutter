import 'dart:convert';
import 'dart:math';

import 'package:faker/faker.dart';
import 'test_objects.dart' as obj;
import 'test_objects_decorators.dart';

var faker = Faker(seed: DateTime.now().millisecondsSinceEpoch);
var counter = 0;
var random = Random(DateTime.now().millisecondsSinceEpoch);

obj.Company generateCompanyRecord() {
  var departments = generateDepartments();
  var company = obj.Company(
      companyId: DateTime.now().millisecondsSinceEpoch + counter++,
      companyName: faker.guid.guid(),
      dateCreated: faker.date.dateTime(),
      departments: departments,
      employeeRecord: {});

  setEmployeeRecords(company, departments);
  return company;
}

void setEmployeeRecords(obj.Company company, List<String> departments) {
  for (var value in departments) {
    company.employeeRecord[value] =
        generateEmployeeRecords(company, random.nextInt(20)).toList();
  }
}

Iterable<obj.Employee> generateEmployeeRecords(
    obj.Company company, int nextInt) sync* {
  for (var i = 0; i < nextInt; i++) {
    yield generateEmployee(company);
  }
}

obj.Employee generateEmployee(obj.Company? company) {
  return obj.Employee(
      empId: DateTime.now().millisecondsSinceEpoch + counter++,
      joinDate: faker.date.dateTime(),
      address: faker.address.streetAddress(),
      emailAddress: faker.internet.email(),
      blob: utf8.encode(faker.lorem.sentence()),
      company: company,
      employeeNote: generateNote());
}

obj.Note generateNote() {
  return obj.Note(
    noteId: DateTime.now().millisecondsSinceEpoch + counter++,
    text: faker.lorem.sentences(random.nextInt(10)).join('. '),
  );
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

obj.Book randomBook() {
  var book = obj.Book();
  book.bookId = randomBookId();
  book.tags = [faker.sport.name(), faker.sport.name(), faker.sport.name()];
  book.description = faker.lorem.sentence();
  book.publisher = faker.company.name();
  book.price = random.nextDouble();
  return book;
}

obj.BookId randomBookId() {
  var bookId = obj.BookId();
  bookId.isbn = faker.guid.guid();
  bookId.author = faker.person.name();
  bookId.name = faker.conference.name();
  return bookId;
}

Product randomProduct() {
  return Product(
      productId: randomProductId(),
      manufacturer: randomManufacturer(),
      productName: faker.guid.guid(),
      price: random.nextDouble());
}

ProductId randomProductId() {
  return ProductId(
      uniqueId: faker.guid.guid(), productCode: faker.internet.macAddress());
}

Manufacturer randomManufacturer() {
  var manufacturer = Manufacturer();
  manufacturer.uniqueId = random.nextInt(100);
  manufacturer.name = faker.company.name();
  manufacturer.address = faker.address.streetAddress();
  return manufacturer;
}

obj.ClassB randomClassB(int seed) {
  var classB = obj.ClassB();
  classB.number = seed + 100;
  classB.text = faker.lorem.sentence();
  return classB;
}

obj.ClassA randomClassA(int seed) {
  var classA = obj.ClassA();
  classA.b = randomClassB(seed);
  classA.uid = faker.guid.guid();
  classA.string = faker.lorem.sentence();
  classA.blob = utf8.encode(faker.lorem.sentence());
  return classA;
}

obj.ClassC randomClassC(int seed) {
  var classC = obj.ClassC();
  classC.id = seed * 5000;
  classC.digit = seed * 69.65;
  classC.parent = randomClassA(seed);
  return classC;
}
