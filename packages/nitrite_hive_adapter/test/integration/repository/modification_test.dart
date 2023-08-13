import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_object_repository_test_loader.dart';
import 'data/data_generator.dart';
import 'data/test_objects.dart';

// ignore: invalid_annotation_target
@Retry(3)
void main() {
  group(retry: 3, 'Repository Modification Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Create Index', () async {
      expect(await companyRepository.hasIndex(['companyName']), true);
      expect(await companyRepository.hasIndex(['dateCreated']), false);

      await companyRepository
          .createIndex(['dateCreated'], indexOptions(IndexType.nonUnique));
      expect(await companyRepository.hasIndex(['dateCreated']), true);
    });

    test('Test Rebuild Index', () async {
      bool error = false;

      try {
        await companyRepository.rebuildIndex(['dateCreated']);
      } on IndexingException {
        error = true;
      } finally {
        expect(error, true);
      }

      await companyRepository
          .createIndex(['dateCreated'], indexOptions(IndexType.nonUnique));
      expect(await companyRepository.hasIndex(['dateCreated']), true);
      await companyRepository.rebuildIndex(['dateCreated']);
    });

    test('Test List Indexes', () async {
      var indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(2));

      await companyRepository
          .createIndex(['dateCreated'], indexOptions(IndexType.nonUnique));
      indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(3));
    });

    test('Test Drop Index', () async {
      var indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(2));

      await companyRepository
          .createIndex(['dateCreated'], indexOptions(IndexType.nonUnique));
      indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(3));

      await companyRepository.dropIndex(['dateCreated']);
      indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(2));
    });

    test('Test Drop All Indexes', () async {
      var indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(2));

      await companyRepository
          .createIndex(['dateCreated'], indexOptions(IndexType.nonUnique));
      indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(3));

      await companyRepository.dropAllIndices();
      indexes = await companyRepository.listIndexes();
      expect(indexes, hasLength(0));
    });

    test('Test Length', () async {
      var cursor = companyRepository.find();
      expect(await cursor.length, 10);
      expect(await cursor.length, await companyRepository.size);
    });

    test('Test Insert', () async {
      var cursor = companyRepository.find();
      var company = generateCompanyRecord();
      expect(await cursor.length, 10);

      await companyRepository.insert(company);
      cursor = companyRepository.find();
      expect(await cursor.length, 11);

      var company1 = generateCompanyRecord();
      var company2 = generateCompanyRecord();
      await companyRepository.insertMany([company1, company2]);
      cursor = companyRepository.find();
      expect(await cursor.length, 13);
    });

    test('Test Update with Filter', () async {
      await employeeRepository.remove(all);

      var employee = Employee();
      employee.company = null;
      employee.address = 'abcd road';
      employee.blob = [1, 2, 125];
      employee.empId = 12;
      employee.joinDate = DateTime.now();
      employee.employeeNote = Note(noteId: 23, text: 'sample text note');

      await employeeRepository.insert(employee);
      var result = employeeRepository.find();
      expect(await result.length, 1);

      await for (var employee in result) {
        expect(employee.address, 'abcd road');
      }

      var updated = Employee(
        empId: employee.empId,
        joinDate: employee.joinDate,
        address: employee.address,
        blob: employee.blob,
        company: employee.company,
        emailAddress: employee.emailAddress,
        employeeNote: employee.employeeNote,
      );
      updated.address = 'xyz road';
      var writeResult =
          await employeeRepository.update(where('empId').eq(12), updated);
      expect(writeResult.getAffectedCount(), 1);
      result = employeeRepository.find();
      expect(await result.length, 1);

      await for (var employee in result) {
        expect(employee.address, 'xyz road');
      }
    });

    test('Test Update with Just Once False', () async {
      var joiningDate = DateTime.now();
      await _prepareUpdateWithOptions(joiningDate);

      var newJoiningDate = DateTime.parse('2012-07-01T16:02:48.440Z');
      var updated1 = createDocument('joinDate', newJoiningDate);

      var writeResult = await employeeRepository
          .updateDocument(where('empId').eq(12), updated1, justOnce: false);
      expect(writeResult.getAffectedCount(), 1);

      var result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 1);
      result =
          employeeRepository.find(filter: where('joinDate').eq(newJoiningDate));
      expect(await result.length, 1);

      await employeeRepository.remove(all);
      await _prepareUpdateWithOptions(joiningDate);
      result = employeeRepository.find();
      expect(await result.length, 2);

      var update = createDocument('joinDate', newJoiningDate);
      writeResult = await employeeRepository.updateDocument(
          where('joinDate').eq(joiningDate), update,
          justOnce: false);
      expect(writeResult.getAffectedCount(), 2);

      result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 0);

      result =
          employeeRepository.find(filter: where('joinDate').eq(newJoiningDate));
      expect(await result.length, 2);
    });

    test('Test Upsert True', () async {
      var joiningDate = DateTime.now();
      var result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 0);

      var employee = Employee();
      employee.company = null;
      employee.address = 'abcd road';
      employee.blob = [1, 2, 125];
      employee.empId = 12;
      employee.joinDate = joiningDate;
      employee.employeeNote = Note(noteId: 23, text: 'sample text note');

      var writeResult = await employeeRepository.update(
          where('empId').eq(12), employee, UpdateOptions(insertIfAbsent: true));
      expect(writeResult.getAffectedCount(), 1);

      result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 1);
    });

    test('Test Upsert False', () async {
      var joiningDate = DateTime.now();
      var result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 0);

      var employee = Employee();
      employee.company = null;
      employee.address = 'abcd road';
      employee.blob = [1, 2, 125];
      employee.empId = 12;
      employee.joinDate = joiningDate;
      employee.employeeNote = Note(noteId: 23, text: 'sample text note');

      var writeResult = await employeeRepository.update(where('empId').eq(12),
          employee, UpdateOptions(insertIfAbsent: false));
      expect(writeResult.getAffectedCount(), 0);

      result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 0);
    });

    test('Test Delete Filter and Without Option', () async {
      var joiningDate = DateTime.now();
      await _prepareUpdateWithOptions(joiningDate);

      var result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 2);

      var writeResult = await employeeRepository
          .remove(where('joinDate').eq(joiningDate), justOne: true);
      expect(writeResult.getAffectedCount(), 1);

      result =
          employeeRepository.find(filter: where('joinDate').eq(joiningDate));
      expect(await result.length, 1);
    });

    test('Test Update with Options', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;

      var update = createDocument('address', 'new address');

      var writeResult = await employeeRepository.updateDocument(
          where('empId').eq(employee.empId), update,
          justOnce: false);
      expect(writeResult.getAffectedCount(), 1);

      var byId = await employeeRepository.getById(employee.empId);
      expect(byId?.address, 'new address');
      expect(byId?.empId, employee.empId);

      update.put('address', 'another address');
      writeResult = await employeeRepository.updateDocument(
          where('empId').eq(employee.empId), update,
          justOnce: false);
      expect(writeResult.getAffectedCount(), 1);

      byId = await employeeRepository.getById(employee.empId);
      expect(byId?.address, 'another address');
      expect(byId?.empId, employee.empId);
    });

    test('Test Multi Update with Object', () async {
      await employeeRepository.remove(all);

      var now = DateTime.now();

      var employee1 = Employee();
      employee1.address = 'abcd';
      employee1.empId = 1;
      employee1.joinDate = now;

      var employee2 = Employee();
      employee2.address = 'xyz';
      employee2.empId = 2;
      employee2.joinDate = now;

      var update = Employee(address: 'new address');

      expect(
          () async => await employeeRepository.update(where('joinDate').eq(now),
              update, updateOptions(insertIfAbsent: false)),
          throwsInvalidIdException);
    });

    test('Test Update Null', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;

      var newEmployee = Employee.clone(employee);
      newEmployee.joinDate = null;

      cursor =
          employeeRepository.find(filter: where('empId').eq(employee.empId));
      var result = await cursor.first;
      expect(result.joinDate, isNotNull);

      var writeResult = await employeeRepository.updateOne(newEmployee);
      expect(writeResult.getAffectedCount(), 1);

      cursor =
          employeeRepository.find(filter: where('empId').eq(employee.empId));
      result = await cursor.first;
      expect(result.joinDate, isNull);
    });

    test('Test Updated with Changed Id', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;
      var oldId = employee.empId;
      var count = await employeeRepository.size;

      var newEmployee = Employee.clone(employee);
      newEmployee.empId = 50;

      cursor = employeeRepository.find(filter: where('empId').eq(oldId));
      employee = await cursor.first;
      expect(employee.joinDate, isNotNull);

      var writeResult = await employeeRepository.update(
          where('empId').eq(oldId),
          newEmployee,
          UpdateOptions(insertIfAbsent: false));
      expect(writeResult.getAffectedCount(), 1);

      expect(await employeeRepository.size, count);
      cursor = employeeRepository.find(filter: where('empId').eq(oldId));
      expect(await cursor.length, 0);
    });

    test('Test Update with Null Id', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;
      var oldId = employee.empId;

      var newEmployee = Employee.clone(employee);
      newEmployee.empId = null;

      cursor = employeeRepository.find(filter: where('empId').eq(oldId));
      employee = await cursor.first;
      expect(employee.joinDate, isNotNull);

      expect(
          () async => await employeeRepository.update(where('empId').eq(oldId),
              newEmployee, UpdateOptions(insertIfAbsent: false)),
          throwsInvalidIdException);
    });

    test('Test Update with Duplicate Id', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;
      var oldId = employee.empId;

      var newEmployee = Employee.clone(employee);
      newEmployee.empId = 5;

      cursor = employeeRepository.find(filter: where('empId').eq(oldId));
      employee = await cursor.first;
      expect(employee.joinDate, isNotNull);

      expect(
          () async => await employeeRepository.update(where('empId').eq(oldId),
              newEmployee, UpdateOptions(insertIfAbsent: false)),
          throwsUniqueConstraintException);
    });

    test('Test Update with Object', () async {
      var cursor = employeeRepository.find();
      var employee = await cursor.first;
      var newEmployee = Employee.clone(employee);

      var id = employee.empId;
      var address = employee.address;
      newEmployee.address = 'new address';

      var writeResult = await employeeRepository.updateOne(newEmployee);
      expect(writeResult.getAffectedCount(), 1);

      cursor = employeeRepository.find(filter: where('empId').eq(id));
      employee = await cursor.first;
      expect(employee.address, isNot(address));
      expect(employee.empId, id);
    });

    test('Test Upsert with Object', () async {
      var employee = Employee(
          address: 'some road',
          blob: [1, 2, 125],
          empId: 12,
          joinDate: DateTime.now(),
          employeeNote: Note(noteId: 23, text: 'sample text note'));

      var writeResult = await employeeRepository.updateOne(employee);
      expect(writeResult.getAffectedCount(), 0);
      writeResult =
          await employeeRepository.updateOne(employee, insertIfAbsent: true);
      expect(writeResult.getAffectedCount(), 1);

      var cursor = employeeRepository.find(filter: where('empId').eq(12));
      var emp = await cursor.first;
      expect(emp, employee);
    });

    test('Test Remove Object', () async {
      var employee = Employee(
          address: 'some road',
          blob: [1, 2, 125],
          empId: 12,
          joinDate: DateTime.now(),
          employeeNote: Note(noteId: 23, text: 'sample text note'));

      var size = await employeeRepository.size;
      var result = await employeeRepository.insert(employee);
      expect(result.getAffectedCount(), 1);
      expect(await employeeRepository.size, size + 1);

      await employeeRepository.removeOne(employee);
      expect(await employeeRepository.size, size);

      var cursor = employeeRepository.find(filter: where('empId').eq(12));
      expect(await cursor.isEmpty, true);
    });

    test('Test Update with Doc', () async {
      var note = Note(noteId: 10, text: 'Some note text');
      var document =
          createDocument('address', 'some address').put('employeeNote', note);

      var result = await employeeRepository.updateDocument(all, document);
      expect(result.getAffectedCount(), 10);
    });

    test('Test Delete with Wrong Filter', () async {
      var notes = await db.getRepository<Note>();
      var one = Note(noteId: 1, text: 'Jane');
      var two = Note(noteId: 2, text: 'Jill');

      await notes.insertMany([one, two]);
      var result = await notes.remove(where('text').eq('Pete'));
      expect(result.getAffectedCount(), 0);
    });

    test('Test Delete', () async {
      var repo = await db.getRepository<WithNitriteId>();
      var one = WithNitriteId();
      one.name = 'Jane';
      await repo.insert(one);

      var cursor = repo.find();
      var item = await cursor.first;
      await repo.removeOne(item);

      expect(() async => await repo.getById(item.idField),
          throwsInvalidIdException);
    });

    test('Test Update Object not exists Upsert True', () async {
      var repo = await db.getRepository<WithNitriteId>();
      var a = WithNitriteId();
      a.name = 'first';
      await repo.insert(a);

      a = WithNitriteId();
      a.name = 'second';

      // it will insert as new object
      await repo.updateOne(a, insertIfAbsent: true);
      expect(await repo.size, 2);
    });

    test('Test Update Object not exists Upsert False', () async {
      var repo = await db.getRepository<WithNitriteId>();
      var a = WithNitriteId();
      a.name = 'first';
      await repo.insert(a);

      a = WithNitriteId();
      a.name = 'second';

      // no changes will happen to repository
      await repo.updateOne(a, insertIfAbsent: false);
      expect(await repo.size, 1);
      var cursor = repo.find();
      expect((await cursor.first).name, 'first');
    });

    test('Test Update Object exists Upsert True', () async {
      var repo = await db.getRepository<WithNullId>();
      var a = WithNullId();
      a.name = 'first';
      a.number = 1;
      await repo.insert(a);

      a = WithNullId();
      a.name = 'first';
      a.number = 2;

      // update existing object, keep id same
      await repo.updateOne(a, insertIfAbsent: true);
      expect(await repo.size, 1);
      var cursor = repo.find();
      expect((await cursor.first).number, 2);
    });

    test('Test Update Object exists Upsert False', () async {
      var repo = await db.getRepository<WithNullId>();
      var a = WithNullId();
      a.name = 'first';
      a.number = 1;
      await repo.insert(a);

      a = WithNullId();
      a.name = 'first';
      a.number = 2;

      // update existing object, keep id same
      await repo.updateOne(a, insertIfAbsent: false);
      expect(await repo.size, 1);
      var cursor = repo.find();
      expect((await cursor.first).number, 2);
    });

    test('Test Nested Update', () async {
      var employee = await employeeRepository.getById(1);
      expect(employee, isNotNull);

      var note = employee?.employeeNote;
      var text = note?.text;
      expect(text, isNotNull);

      var update = createDocument('employeeNote.text', 'some updated text');
      var writeResult = await employeeRepository
          .updateDocument(where("empId").eq(1), update, justOnce: false);
      expect(writeResult.getAffectedCount(), 1);

      employee = await employeeRepository.getById(1);
      expect(employee, isNotNull);

      note = employee?.employeeNote;
      expect(note, isNotNull);
      expect(text, isNot(note?.text));
      expect(note?.text, 'some updated text');
    });
  });
}

_prepareUpdateWithOptions(DateTime joiningDate) async {
  await employeeRepository.remove(all);

  var employee1 = Employee();
  employee1.company = null;
  employee1.address = 'some road';
  employee1.blob = [1, 2, 125];
  employee1.empId = 12;
  employee1.joinDate = joiningDate;
  employee1.employeeNote = Note(noteId: 23, text: 'sample text note');

  var employee2 = Employee();
  employee2.company = null;
  employee2.address = 'other road';
  employee2.blob = [10, 12, 25];
  employee2.empId = 2;
  employee2.joinDate = joiningDate;
  employee2.employeeNote = Note(noteId: 2, text: 'some random note');

  await employeeRepository.insertMany([employee1, employee2]);
  var result = employeeRepository.find();
  expect(await result.length, 2);

  await for (var e in result.project<Employee>()) {
    expect(e.joinDate, joiningDate);
  }
}
