import 'package:faker/faker.dart' as fk;
import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../test_utils.dart';
import 'base_object_repository_test_loader.dart';
import 'data/data_generator.dart';
import 'data/test_objects.dart';

void main() {
  group('Repository Search Test', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Find with Options', () async {
      var cursor =
          employeeRepository.find(findOptions: skipBy(0).setLimit(1));
      expect(await cursor.length, 1);
      expect(await cursor.first, isNotNull);
    });

    test('Test Employee Projection', () async {
      var employeeList = await (employeeRepository.find()).toList();
      var subEmployeeList = await (employeeRepository.find())
          .project<SubEmployee>()
          .toList();
      expect(employeeList, isNotEmpty);
      expect(subEmployeeList, isNotEmpty);
      expect(employeeList.length, subEmployeeList.length);

      for (var i = 0; i < subEmployeeList.length; i++) {
        var employee = employeeList[i];
        var subEmployee = subEmployeeList[i];

        expect(employee.empId, subEmployee.empId);
        expect(employee.joinDate, subEmployee.joinDate);
        expect(employee.address, subEmployee.address);
      }

      var cursor = employeeRepository.find();
      expect(await cursor.first, isNotNull);
    });

    test('Test Empty Result Projection', () async {
      await employeeRepository.remove(all);
      var cursor = employeeRepository.find();
      expect(await cursor.length, 0);

      cursor = employeeRepository.find(filter: where('empId').eq(-1));
      expect(await cursor.length, 0);
    });

    test('Test Get by Id', () async {
      var empRepo = await db.getRepository<Employee>();
      await empRepo.remove(all);

      var e1 = generateEmployee(null);
      var e2 = generateEmployee(null);
      var e3 = generateEmployee(null);
      var e4 = generateEmployee(null);

      e1.empId = 10000;
      e2.empId = 20000;
      e3.empId = 30000;
      e4.empId = 40000;

      await empRepo.insertMany([e1, e2, e3, e4]);

      var byId = await empRepo.getById(10000);
      expect(byId, e1);
    });

    test('Test Get byId no Id', () async {
      var faker = fk.Faker();
      var repository = await db.getRepository<Note>();
      var n1 = Note(
        noteId: 10000,
        text: faker.lorem.sentences(random.nextInt(10)).join('. '),
      );
      var n2 = Note(
        noteId: 20000,
        text: faker.lorem.sentences(random.nextInt(10)).join('. '),
      );
      var n3 = Note(
        noteId: 30000,
        text: faker.lorem.sentences(random.nextInt(10)).join('. '),
      );

      await repository.insertMany([n1, n2, n3]);
      expect(() async => await repository.getById(20000),
          throwsInvalidIdException);
    });

    test('Test Get by Id Null Id', () async {
      var empRepo = await db.getRepository<Employee>();
      var e1 = generateEmployee(null);
      var e2 = generateEmployee(null);
      var e3 = generateEmployee(null);
      var e4 = generateEmployee(null);

      e1.empId = 10000;
      e2.empId = 20000;
      e3.empId = 30000;
      e4.empId = 40000;

      await empRepo.insertMany([e1, e2, e3, e4]);
      expect(() async => await empRepo.getById(null), throwsInvalidIdException);
    });

    test('Test Get by Id Wrong Type', () async {
      var empRepo = await db.getRepository<Employee>();
      var e1 = generateEmployee(null);
      var e2 = generateEmployee(null);
      var e3 = generateEmployee(null);
      var e4 = generateEmployee(null);

      e1.empId = 10000;
      e2.empId = 20000;
      e3.empId = 30000;
      e4.empId = 40000;

      await empRepo.insertMany([e1, e2, e3, e4]);
      expect(() async => await empRepo.getById('employee'),
          throwsInvalidIdException);
    });

    test('Test Equal Filter by Id', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;
      var empId = employee.empId;

      cursor = employeeRepository.find(filter: where('empId').eq(empId));
      var emp = await cursor.project<Employee>().first;
      expect(employee, emp);
    });

    test('Test Equal Filter', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;

      cursor = employeeRepository.find(
          filter: where('joinDate').eq(employee.joinDate));
      var emp = await cursor.project<Employee>().first;
      expect(employee, emp);
    });

    test('Test String Equal Filter', () async {
      var repository = await db.getRepository<ProductScore>();
      var object = ProductScore();
      object.product = 'test';
      object.score = 1;
      await repository.insert(object);

      object = ProductScore();
      object.product = 'test';
      object.score = 2;
      await repository.insert(object);

      object = ProductScore();
      object.product = 'another-test';
      object.score = 3;
      await repository.insert(object);

      var cursor = repository.find(filter: where('product').eq('test'));
      expect(await cursor.length, 2);
    });

    test('Test And Filter', () async {
      var cursor = employeeRepository.find();
      var emp = await cursor.first;

      var id = emp.empId;
      var address = emp.address;
      var joinDate = emp.joinDate;

      cursor = employeeRepository.find(
          filter: and([
        where('empId').eq(id),
        where('address').regex(address),
        where('joinDate').eq(joinDate),
      ]));
      var employee = await cursor.first;
      expect(emp, employee);
    });

    test('Test Or Filter', () async {
      var cursor = employeeRepository.find();
      var emp = await cursor.first;

      var id = emp.empId;

      cursor = employeeRepository.find(
          filter: or([
        where('empId').eq(id),
        where('address').text('n/a'),
        where('joinDate').eq(null),
      ]));
      var employee = await cursor.first;
      expect(emp, employee);
    });

    test('Test Not Filter', () async {
      var cursor = employeeRepository.find();
      var emp = await cursor.first;
      var id = emp.empId;

      cursor = employeeRepository.find(
        filter: where('empId').eq(id).not(),
      );
      var employee = await cursor.first;
      expect(emp, isNot(employee));
    });

    test('Test Greater Filter', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.ascending));
      var emp = await cursor.first;
      var id = emp.empId;

      cursor = employeeRepository.find(
        filter: where('empId').gt(id),
      );

      expect(await cursor.toList(), isNot(contains(emp)));
      expect(await cursor.length, 9);
    });

    test('Test Greater Equal Filter', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.ascending));
      var emp = await cursor.first;
      var id = emp.empId;

      cursor = employeeRepository.find(
        filter: where('empId').gte(id),
      );

      expect(await cursor.toList(), contains(emp));
      expect(await cursor.length, 10);
    });

    test('Test Lesser Filter', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.descending));
      var emp = await cursor.first;
      var id = emp.empId;

      cursor = employeeRepository.find(
        filter: where('empId').lt(id),
      );

      expect(await cursor.toList(), isNot(contains(emp)));
      expect(await cursor.length, 9);
    });

    test('Test Lesser Equal Filter', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.descending));
      var emp = await cursor.first;
      var id = emp.empId;

      cursor = employeeRepository.find(
        filter: where('empId').lte(id),
      );

      expect(await cursor.toList(), contains(emp));
      expect(await cursor.length, 10);
    });

    test('Test Text Filter', () async {
      var cursor = employeeRepository.find();
      var emp = await cursor.first;
      var text = emp.employeeNote?.text as String;

      cursor = employeeRepository.find(
          filter: where('employeeNote.text').text(text));
      expect(await cursor.toList(), contains(emp));
    });

    test('Test Regex Filter', () async {
      var cursor = employeeRepository.find();
      var count = await cursor.length;

      cursor = employeeRepository.find(
          filter: where('emailAddress')
              .regex('^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\$'));
      expect(await cursor.length, count);
    });

    test('Test In Filter', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.descending));
      var emp = await cursor.first;
      var id = emp.empId as int;

      cursor = employeeRepository.find(
          filter: where('empId').within([id, id - 1, id - 2]));

      expect(await cursor.toList(), contains(emp));
      expect(await cursor.length, 3);

      cursor = employeeRepository.find(
          filter: where('empId').within([id - 1, id - 2]));
      expect(await cursor.length, 2);
    });

    test('Test Not In Filter', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.descending));
      var emp = await cursor.first;
      var id = emp.empId as int;

      cursor = employeeRepository.find(
          filter: where('empId').notIn([id, id - 1, id - 2]));

      expect(await cursor.toList(), isNot(contains(emp)));
      expect(await cursor.length, 7);

      cursor = employeeRepository.find(
          filter: where('empId').notIn([id - 1, id - 2]));
      expect(await cursor.length, 8);
    });

    test('Test ElemMatch Filter', () async {
      var score1 = ProductScore()
        ..product = 'abc'
        ..score = 10;
      var score2 = ProductScore()
        ..product = 'abc'
        ..score = 8;
      var score3 = ProductScore()
        ..product = 'abc'
        ..score = 7;
      var score4 = ProductScore()
        ..product = 'xyz'
        ..score = 5;
      var score5 = ProductScore()
        ..product = 'xyz'
        ..score = 7;
      var score6 = ProductScore()
        ..product = 'xyz'
        ..score = 8;

      var repository = await db.getRepository<ElemMatch>();
      var e1 = ElemMatch()
        ..id = 1
        ..strArray = ['a', 'b']
        ..productScores = [score1, score4];

      var e2 = ElemMatch()
        ..id = 2
        ..strArray = ['d', 'e']
        ..productScores = [score2, score5];

      var e3 = ElemMatch()
        ..id = 3
        ..strArray = ['a', 'f']
        ..productScores = [score3, score6];

      await repository.insertMany([e1, e2, e3]);

      var cursor = repository.find(
          filter: where('productScores').elemMatch(
              where('product').eq('xyz').and(where('score').gte(8))));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter:
              where('productScores').elemMatch(where('score').lte(8).not()));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter: where('productScores')
              .elemMatch(where('product').eq('xyz').or(where('score').gte(8))));
      expect(await cursor.length, 3);

      cursor = repository.find(
          filter: where('productScores').elemMatch(where('product').eq('xyz')));
      expect(await cursor.length, 3);

      cursor = repository.find(
          filter: where('productScores').elemMatch(where('score').gte(10)));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter: where('productScores').elemMatch(where('score').gt(8)));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter: where('productScores').elemMatch(where('score').lt(7)));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter: where('productScores').elemMatch(where('score').lte(7)));
      expect(await cursor.length, 3);

      cursor = repository.find(
          filter:
              where('productScores').elemMatch(where('score').within([7, 8])));
      expect(await cursor.length, 2);

      cursor = repository.find(
          filter:
              where('productScores').elemMatch(where('score').notIn([7, 8])));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter:
              where('productScores').elemMatch(where('product').regex('xyz')));
      expect(await cursor.length, 3);

      cursor =
          repository.find(filter: where('strArray').elemMatch($.eq('a')));
      expect(await cursor.length, 2);

      cursor = repository.find(
          filter: where('strArray')
              .elemMatch($.eq('a').or($.eq('f').or($.eq('b'))).not()));
      expect(await cursor.length, 1);

      cursor =
          repository.find(filter: where('strArray').elemMatch($.gt('e')));
      expect(await cursor.length, 1);

      cursor = repository.find(
          filter: where('strArray').elemMatch($.gte('e')));
      expect(await cursor.length, 2);

      cursor = repository.find(
          filter: where('strArray').elemMatch($.lte('b')));
      expect(await cursor.length, 2);

      cursor =
          repository.find(filter: where('strArray').elemMatch($.lt('a')));
      expect(await cursor.length, 0);

      cursor = repository.find(
          filter: where('strArray').elemMatch($.within(['a', 'f'])));
      expect(await cursor.length, 2);

      cursor = repository.find(
          filter: where('strArray').elemMatch($.regex('a')));
      expect(await cursor.length, 2);
    });

    test('Test Filter All', () async {
      var repository = await db.getRepository<ElemMatch>();
      var cursor = repository.find(filter: all);
      expect(await cursor.length, 0);

      await repository.insert(ElemMatch());
      cursor = repository.find(filter: all);
      expect(await cursor.length, 1);
    });

    test('Test Equals on Text Index', () async {
      var p1 = PersonEntity()
        ..name = 'jhonny'
        ..dateCreated = DateTime.now()
        ..uuid = Uuid().v4();
      var p2 = PersonEntity()
        ..name = 'jhonny'
        ..dateCreated = DateTime.now()
        ..uuid = Uuid().v4();
      var p3 = PersonEntity()
        ..name = 'jhonny'
        ..dateCreated = DateTime.now()
        ..uuid = Uuid().v4();

      var repository = await db.getRepository<PersonEntity>();
      await repository.insertMany([p1, p2, p3]);

      var cursor = repository.find(filter: where('name').eq('jhonny'));
      expect(() async => await cursor.length, throwsFilterException);
    });

    test('Test Sort', () async {
      var p1 = PersonEntity()
        ..name = 'abcd'
        ..status = 'Married'
        ..dateCreated = DateTime.now()
        ..uuid = Uuid().v4();

      var p2 = PersonEntity()
        ..name = 'efgh'
        ..status = 'Married'
        ..dateCreated = DateTime.now()
        ..uuid = Uuid().v4();

      var p3 = PersonEntity()
        ..name = 'ijkl'
        ..status = 'Un-Married'
        ..dateCreated = DateTime.now()
        ..uuid = Uuid().v4();

      var repository = await db.getRepository<PersonEntity>();
      await repository.insertMany([p1, p2, p3]);

      var marriedFilter = where('status').eq('Married');

      var cursor = repository.find(filter: marriedFilter);
      expect(await cursor.length, 2);

      cursor = repository.find(
          filter: marriedFilter,
          findOptions: orderBy('status', SortOrder.descending));
      expect(await cursor.length, 2);

      cursor = repository.find(
          findOptions: orderBy('status', SortOrder.descending));
      expect((await cursor.first).status, 'Un-Married');

      cursor = repository.find(
          findOptions: orderBy('status', SortOrder.ascending));
      expect(await cursor.length, 3);

      cursor = repository.find(
          findOptions: orderBy('status', SortOrder.ascending));
      expect((await cursor.first).status, 'Married');
    });

    test('Test Repeatable Index Annotation', () async {
      var repo = await db.getRepository<RepeatableIndexTest>();
      var first = RepeatableIndexTest()
        ..age = 12
        ..firstName = 'fName'
        ..lastName = 'lName';
      await repo.insert(first);

      expect(await repo.hasIndex(['firstName']), true);
      expect(await repo.hasIndex(['age']), true);
      expect(await repo.hasIndex(['lastName']), true);

      var cursor = repo.find(filter: where('age').eq(12));
      expect(await cursor.first, first);
    });

    test('Test Id Set', () async {
      var cursor = employeeRepository.find(
          findOptions: orderBy('empId', SortOrder.ascending));
      expect(await cursor.length, 10);
    });

    test('Test Between Filter', () async {
      var documentMapper = db.config.nitriteMapper as EntityConverterMapper;
      documentMapper.registerEntityConverter(_TestDataConverter());

      var data1 = _TestData(DateTime.parse('2020-01-11'));
      var data2 = _TestData(DateTime.parse('2021-02-12'));
      var data3 = _TestData(DateTime.parse('2022-03-13'));
      var data4 = _TestData(DateTime.parse('2023-04-14'));
      var data5 = _TestData(DateTime.parse('2024-05-15'));
      var data6 = _TestData(DateTime.parse('2025-06-16'));

      var repository = await db.getRepository<_TestData>();
      await repository.insertMany([data1, data2, data3, data4, data5, data6]);

      var cursor = repository.find(
          filter: where('age').between(
              DateTime.parse('2020-01-11'), DateTime.parse('2025-06-16')));
      expect(await cursor.length, 6);

      cursor = repository.find(
          filter: where('age').between(
              DateTime.parse('2020-01-11'), DateTime.parse('2025-06-16'),
              lowerInclusive: false, upperInclusive: false));
      expect(await cursor.length, 4);

      cursor = repository.find(
          filter: where('age').between(
              DateTime.parse('2020-01-11'), DateTime.parse('2025-06-16'),
              lowerInclusive: false, upperInclusive: true));
      expect(await cursor.length, 5);
    });

    test('Test Find by Entity Id', () async {
      var bookRepo = await db.getRepository<Book>();
      var book = randomBook();
      await bookRepo.insert(book);

      var result = await bookRepo.updateDocument(where('book_id').eq(book.bookId), createDocument('price', 100.0));
      expect(result.getAffectedCount(), 1);

      var cursor = bookRepo.find(filter: where('price').eq(100.0));
      expect(await cursor.length, 1);
    });
  });
}

class _TestData {
  final DateTime? age;
  _TestData(this.age);
}

class _TestDataConverter extends EntityConverter<_TestData> {
  @override
  _TestData fromDocument(Document document, NitriteMapper nitriteMapper) {
    return _TestData(document['age'] as DateTime?);
  }

  @override
  Document toDocument(_TestData entity, NitriteMapper nitriteMapper) {
    return createDocument('age', entity.age);
  }
}
