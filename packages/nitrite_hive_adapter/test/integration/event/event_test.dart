import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../repository/base_object_repository_test_loader.dart';
import '../repository/data/data_generator.dart';
import '../repository/data/test_objects.dart';

void main() {
  group('Event Test Suite', () {
    EventType? action;
    dynamic item;
    late CollectionEventListener listener;

    setUp(() async {
      setUpLog();
      await setUpNitriteTest();

      listener = (event) {
        action = event.eventType;
        item = event.item;
      };

      employeeRepository.subscribe(listener);
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Insert', () async {
      var employee = generateEmployee(null);
      employee.empId = 100;

      await employeeRepository.insert(employee);
      await Future.delayed(Duration(milliseconds: 100));
      expect(action, EventType.insert);
      expect(item, isNotNull);
    });

    test('Test Update', () async {
      var employee = generateEmployee(null);
      employee.empId = 100;

      await employeeRepository.insert(employee);
      await Future.delayed(Duration(milliseconds: 100));
      expect(action, EventType.insert);
      expect(item, isNotNull);

      employee.address = 'xyz';
      await employeeRepository.update(where('empId').eq(100), employee);
      await Future.delayed(Duration(milliseconds: 100));
      expect(action, EventType.update);
      expect(item, isNotNull);

      var byId = await employeeRepository.getById(100);
      expect(byId?.address, 'xyz');
    });

    test('Test Upsert', () async {
      var employee = generateEmployee(null);
      employee.empId = 100;
      employee.address = 'abcd';

      await employeeRepository.update(where('empId').eq(100), employee,
          UpdateOptions(insertIfAbsent: true));
      await Future.delayed(Duration(milliseconds: 100));
      expect(action, EventType.insert);
      expect(item, isNotNull);
    });

    test('Test Delete', () async {
      var employee = generateEmployee(null);
      employee.empId = 100;
      employee.address = 'abcd';

      await employeeRepository.insert(employee);
      await Future.delayed(Duration(milliseconds: 100));
      expect(action, EventType.insert);

      await employeeRepository.remove(where('empId').eq(100));
      await Future.delayed(Duration(milliseconds: 100));
      expect(action, EventType.remove);
      expect(item, isNotNull);
    });

    test('Test Drop', () async {
      var repository = await db.getRepository<Employee>(key: 'test');
      item = null;

      var employee = generateEmployee(null);
      employee.empId = 100;
      employee.address = 'abcd';
      await repository.insert(employee);

      await repository.drop();
      await Future.delayed(Duration(milliseconds: 100));
      expect(item, isNull);
    });

    test('Test Close', () async {
      item = null;
      var repository = await db.getRepository<Employee>(key: 'test');
      if (repository.isOpen) {
        await repository.close();
      }

      expect(item, isNull);
    });

    test('Test Deregister', () async {
      employeeRepository.unsubscribe(listener);
      item = null;

      var employee = generateEmployee(null);
      employee.empId = 100;
      employee.address = 'abcd';
      await employeeRepository.insert(employee);

      await Future.delayed(Duration(milliseconds: 100));
      expect(item, isNull);
    });

    test('Test Multiple Listeners', () async {
      var count = 0;
      employeeRepository.subscribe((event) {
        count++;
      });
      employeeRepository.subscribe((event) {
        count++;
      });

      var employee = generateEmployee(null);
      employee.empId = 100;
      employee.address = 'abcd';
      await employeeRepository.insert(employee);

      await Future.delayed(Duration(milliseconds: 100));
      expect(count, 2);
    });

    test('Test Single Event Listener', () async {
      var count = 0;
      employeeRepository.subscribe((event) {
        count++;
      });

      var employee = generateEmployee(null);
      employee.empId = 100;
      employee.address = 'abcd';
      await employeeRepository.insert(employee);

      await Future.delayed(Duration(milliseconds: 100));
      expect(count, 1);
    });
  });
}
