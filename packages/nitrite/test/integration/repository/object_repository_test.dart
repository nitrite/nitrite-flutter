import 'package:faker/faker.dart' as f;
import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';
import 'data/test_objects_decorators.dart';

part 'object_repository_test.no2.dart';

void main() {
  group(retry: 3, 'Object Repository Test Suite', () {
    late Nitrite db;

    setUp(() async {
      setUpLog();
      db = await Nitrite.builder().openOrCreate();

      var mapper = db.config.nitriteMapper as SimpleNitriteMapper;
      mapper.registerEntityConverter(StressRecordConverter());
      mapper.registerEntityConverter(WithDateIdConverter());
      mapper.registerEntityConverter(WithTransientFieldConverter());
      mapper.registerEntityConverter(WithOutIdConverter());
      mapper.registerEntityConverter(ChildClassConverter());
      mapper.registerEntityConverter(EmployeeConverter());
      mapper.registerEntityConverter(EmployeeEntityConverter());
      mapper.registerEntityConverter(CompanyConverter());
      mapper.registerEntityConverter(NoteConverter());
      mapper.registerEntityConverter(ProductConverter());
      mapper.registerEntityConverter(ProductIdConverter());
      mapper.registerEntityConverter(ManufacturerConverter());
      mapper.registerEntityConverter(MiniProductConverter());
    });

    tearDown(() async {
      if (!db.isClosed) {
        await db.close();
      }
    });

    test('Test Without Id', () async {
      var repo = await db.getRepository<WithOutId>();
      expect(await repo.hasIndex(['name']), false);
      expect(await repo.hasIndex(['number']), false);

      var object = WithOutId(name: 'test', number: 2);

      await repo.insert(object);
      var cursor = repo.find();
      var instance = await cursor.first;
      expect(object, instance);
    });

    test('Test With Ignored Field', () async {
      var repo = await db.getRepository<WithTransientField>(
          entityDecorator: WithTransientFieldDecorator());
      expect(await repo.hasIndex(['number']), true);

      var object = WithTransientField(name: 'test', number: 2);
      await repo.insert(object);

      var instance = await repo.getById(2);
      expect(object, isNot(instance));
      expect(instance?.name, isNull);
      expect(object.number, instance?.number);
    });

    test('Test Write Thousand Records', () async {
      Logger.root.level = Level.OFF;
      var count = 5000;
      var faker = f.Faker();

      var stopWatch = Stopwatch();
      stopWatch.start();
      var repo = await db.getRepository<StressRecord>();
      for (var i = 0; i < count; i++) {
        var record = StressRecord();
        record.firstName = faker.person.firstName();
        record.failed = false;
        record.lastName = faker.person.lastName();
        record.processed = false;

        await repo.insert(record);
      }

      var cursor = repo.find(filter: where('failed').eq(false));
      await for (var record in cursor) {
        record.processed = true;
        await repo.update(where('firstName').eq(record.firstName), record);
      }

      expect(await repo.size, 5000);
      var sequentialTime = stopWatch.elapsed;
      print('Sequential Time (s) - ${sequentialTime.inMilliseconds}');
    });

    test('Test With Date as Id', () async {
      var repo = await db.getRepository<WithDateId>(
          entityDecorator: WithDateIdDecorator());
      expect(await repo.hasIndex(['id']), true);

      var object1 = WithDateId(
          id: DateTime.fromMillisecondsSinceEpoch(1482773634000),
          name: 'first date');
      var object2 = WithDateId(
          id: DateTime.fromMillisecondsSinceEpoch(1482773720000),
          name: 'second date');
      await repo.insertMany([object1, object2]);

      var cursor = repo.find(
          filter: where('id')
              .eq(DateTime.fromMillisecondsSinceEpoch(1482773634000)));
      var item = await cursor.first;
      expect(item, object1);

      cursor = repo.find(
          filter: where('id')
              .eq(DateTime.fromMillisecondsSinceEpoch(1482773720000)));
      item = await cursor.first;
      expect(item, object2);
    });

    test('Test with Id Inheritence', () async {
      var repository = await db.getRepository<ChildClass>();
      expect(await repository.hasIndex(['id']), true);
      expect(await repository.hasIndex(['date']), true);
      expect(await repository.hasIndex(['text']), true);

      var childClass = ChildClass();
      childClass.name = 'first';
      childClass.date = DateTime.fromMillisecondsSinceEpoch(10000000);
      childClass.id = 1;
      childClass.text = 'I am first class';
      await repository.insert(childClass);

      childClass = ChildClass();
      childClass.name = 'second';
      childClass.date = DateTime.fromMillisecondsSinceEpoch(10000001);
      childClass.id = 2;
      childClass.text = 'I am second class';
      await repository.insert(childClass);

      childClass = ChildClass();
      childClass.name = 'third';
      childClass.date = DateTime.fromMillisecondsSinceEpoch(10000002);
      childClass.id = 3;
      childClass.text = 'I am third class';
      await repository.insert(childClass);

      var cursor = repository.find(filter: where('text').text('class'));
      expect(await cursor.length, 3);

      // stop word second discarded
      cursor = repository.find(filter: where('text').text('second'));
      expect(await cursor.length, 0);

      cursor = repository.find(
          filter:
              where('date').eq(DateTime.fromMillisecondsSinceEpoch(10000000)));
      expect(await cursor.length, 1);

      cursor = repository.find(filter: where('id').eq(1));
      expect(await cursor.length, 1);
    });

    test('Test Attributes', () async {
      var repository = await db.getRepository<WithDateId>(
          entityDecorator: WithDateIdDecorator());
      expect(await repository.hasIndex(['id']), true);

      var attributes = Attributes(repository.documentCollection.name);
      await repository.setAttributes(attributes);
      expect(await repository.getAttributes(), attributes);
    });

    test('Test Keyed Repository', () async {
      var managerRepo = await db.getRepository<Employee>(key: 'managers');
      var employeeRepo = await db.getRepository<Employee>();
      var developerRepo = await db.getRepository<Employee>(key: 'developers');

      var manager = Employee();
      manager.empId = 1;
      manager.address = 'abcd';
      manager.joinDate = DateTime.now();

      var developer = Employee();
      developer.empId = 2;
      developer.address = 'xyz';
      developer.joinDate = DateTime.now();

      await managerRepo.insert(manager);
      await employeeRepo.insertMany([manager, developer]);
      await developerRepo.insert(developer);

      expect(await db.hasRepository<Employee>(), true);
      expect(await db.hasRepository<Employee>(key: 'managers'), true);
      expect(await db.hasRepository<Employee>(key: 'developers'), true);

      expect(await db.listRepositories, hasLength(1));
      expect(await db.listKeyedRepositories, hasLength(2));

      var cursor = employeeRepo.find(filter: where('address').text('abcd'));
      expect(await cursor.length, 1);

      cursor = employeeRepo.find(filter: where('address').text('xyz'));
      expect(await cursor.length, 1);

      cursor = managerRepo.find(filter: where('address').text('xyz'));
      expect(await cursor.length, 0);

      cursor = employeeRepo.find(filter: where('address').text('abcd'));
      expect(await cursor.length, 1);

      cursor = developerRepo.find(filter: where('address').text('xyz'));
      expect(await cursor.length, 1);

      cursor = developerRepo.find(filter: where('address').text('abcd'));
      expect(await cursor.length, 0);
    });

    test('Test Entity Repository', () async {
      var managerRepo = await db.getRepository<EmployeeEntity>(key: 'managers');
      var employeeRepo = await db.getRepository<EmployeeEntity>();
      var developerRepo =
          await db.getRepository<EmployeeEntity>(key: 'developers');

      await managerRepo
          .insertMany([EmployeeEntity(), EmployeeEntity(), EmployeeEntity()]);
      await employeeRepo
          .insertMany([EmployeeEntity(), EmployeeEntity(), EmployeeEntity()]);
      await developerRepo
          .insertMany([EmployeeEntity(), EmployeeEntity(), EmployeeEntity()]);

      bool errored = false;
      try {
        var collection = await db.getCollection('entity.employee');
        collection.find();
      } on ValidationException {
        errored = true;
      }
      expect(errored, true);

      expect((await db.listRepositories).contains('entity.employee'), true);
      expect(await db.listKeyedRepositories, hasLength(2));
      expect(await db.listCollectionNames, hasLength(0));

      expect(await managerRepo.hasIndex(['firstName']), true);
      expect(await managerRepo.hasIndex(['lastName']), true);
      expect(await employeeRepo.hasIndex(['firstName']), true);
      expect(await employeeRepo.hasIndex(['lastName']), true);

      await managerRepo.drop();
      expect(await db.listKeyedRepositories, hasLength(1));
    });

    test('Test Repository Single Instance', () async {
      var employeeRepo = await db.getRepository<EmployeeEntity>();
      var counter = 0;
      employeeRepo.subscribe((event) {
        counter += 1;
      });

      var employeeRepo2 = await db.getRepository<EmployeeEntity>();
      await employeeRepo2.insert(EmployeeEntity());

      // wait for 1 sec for the event to be fired
      await Future.delayed(Duration(seconds: 1));
      expect(counter, 1);
    });

    test('Test Repository Name', () async {
      var productRepository =
          await db.getRepository<Product>(entityDecorator: ProductDecorator());
      var upcomingProductRepository = await db.getRepository<Product>(
          entityDecorator: ProductDecorator(), key: 'upcoming');
      var manufacturerRepository = await db.getRepository<Manufacturer>(
          entityDecorator: ManufacturerDecorator());
      var exManufacturerRepository = await db.getRepository<Manufacturer>(
          entityDecorator: ManufacturerDecorator(), key: 'ex');
      var employeeRepository = await db.getRepository<Employee>();
      var managerRepository = await db.getRepository<Employee>(key: 'manager');

      expect(productRepository.documentCollection.name, 'product');
      expect(upcomingProductRepository.documentCollection.name,
          'product+upcoming');
      expect(manufacturerRepository.documentCollection.name, 'Manufacturer');
      expect(
          exManufacturerRepository.documentCollection.name, 'Manufacturer+ex');
      expect(employeeRepository.documentCollection.name, 'Employee');
      expect(managerRepository.documentCollection.name, 'Employee+manager');
    });

    test('Test Repository Type', () async {
      var productRepository =
          await db.getRepository<Product>(entityDecorator: ProductDecorator());
      var upcomingProductRepository = await db.getRepository<Product>(
          entityDecorator: ProductDecorator(), key: 'upcoming');
      var manufacturerRepository = await db.getRepository<Manufacturer>(
          entityDecorator: ManufacturerDecorator());
      var exManufacturerRepository = await db.getRepository<Manufacturer>(
          entityDecorator: ManufacturerDecorator(), key: 'ex');
      var employeeRepository = await db.getRepository<Employee>();
      var managerRepository = await db.getRepository<Employee>(key: 'manager');

      expect(productRepository.getType(), Product);
      expect(upcomingProductRepository.getType(), Product);
      expect(manufacturerRepository.getType(), Manufacturer);
      expect(exManufacturerRepository.getType(), Manufacturer);
      expect(employeeRepository.getType(), Employee);
      expect(managerRepository.getType(), Employee);
    });

    test('Test Destroy Repository', () async {
      var productRepository =
          await db.getRepository<Product>(entityDecorator: ProductDecorator());
      var upcomingProductRepository = await db.getRepository<Product>(
          entityDecorator: ProductDecorator(), key: 'upcoming');
      var manufacturerRepository = await db.getRepository<Manufacturer>(
          entityDecorator: ManufacturerDecorator());
      var exManufacturerRepository = await db.getRepository<Manufacturer>(
          entityDecorator: ManufacturerDecorator(), key: 'ex');
      var employeeRepository = await db.getRepository<Employee>();
      var managerRepository = await db.getRepository<Employee>(key: 'manager');

      expect(productRepository, isNotNull);
      expect(upcomingProductRepository, isNotNull);
      expect(manufacturerRepository, isNotNull);
      expect(exManufacturerRepository, isNotNull);
      expect(employeeRepository, isNotNull);
      expect(managerRepository, isNotNull);

      expect(await db.hasRepository(entityDecorator: ProductDecorator()), true);
      expect(
          await db.hasRepository(
              entityDecorator: ProductDecorator(), key: 'upcoming'),
          true);
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          true);
      expect(
          await db.hasRepository(
              entityDecorator: ManufacturerDecorator(), key: 'ex'),
          true);
      expect(await db.hasRepository<Employee>(), true);
      expect(await db.hasRepository<Employee>(key: 'manager'), true);

      await db.destroyRepository(entityDecorator: ProductDecorator());
      expect(
          await db.hasRepository(entityDecorator: ProductDecorator()), false);
      expect(
          await db.hasRepository(
              entityDecorator: ProductDecorator(), key: 'upcoming'),
          true);

      await db.destroyRepository(
          entityDecorator: ProductDecorator(), key: 'upcoming');
      expect(
          await db.hasRepository(entityDecorator: ProductDecorator()), false);
      expect(
          await db.hasRepository(
              entityDecorator: ProductDecorator(), key: 'upcoming'),
          false);

      await db.destroyRepository(entityDecorator: ManufacturerDecorator());
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          false);
      expect(
          await db.hasRepository(
              entityDecorator: ManufacturerDecorator(), key: 'ex'),
          true);

      await db.destroyRepository(
          entityDecorator: ManufacturerDecorator(), key: 'ex');
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          false);
      expect(
          await db.hasRepository(
              entityDecorator: ManufacturerDecorator(), key: 'ex'),
          false);

      await db.destroyRepository<Employee>();
      expect(await db.hasRepository<Employee>(), false);
      expect(await db.hasRepository<Employee>(key: 'manager'), true);

      await db.destroyRepository<Employee>(key: 'manager');
      expect(await db.hasRepository<Employee>(), false);
      expect(await db.hasRepository<Employee>(key: 'manager'), false);
    });

    test('Test Destroy Repository Wrong Decorator', () async {
      var productRepository =
          await db.getRepository(entityDecorator: ProductDecorator());
      expect(productRepository, isNotNull);
      expect(await db.hasRepository(entityDecorator: ProductDecorator()), true);
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          false);

      await db.destroyRepository(entityDecorator: ManufacturerDecorator());
      expect(await db.hasRepository(entityDecorator: ProductDecorator()), true);
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          false);
    });

    test('Test Destroy Repository Wrong Decorator with Key', () async {
      var productRepository = await db.getRepository(
          entityDecorator: ProductDecorator(), key: 'upcoming');
      expect(productRepository, isNotNull);
      expect(
          await db.hasRepository(
              entityDecorator: ProductDecorator(), key: 'upcoming'),
          true);
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          false);

      await db.destroyRepository(
          entityDecorator: ManufacturerDecorator(), key: 'upcoming');
      expect(
          await db.hasRepository(
              entityDecorator: ProductDecorator(), key: 'upcoming'),
          true);
      expect(await db.hasRepository(entityDecorator: ManufacturerDecorator()),
          false);
    });

    test('Test Destroy Repository Wrong Class Name', () async {
      var productRepository =
          await db.getRepository(entityDecorator: ProductDecorator());
      expect(productRepository, isNotNull);
      expect(await db.hasRepository<Product>(), false);

      await db.destroyRepository<Product>();
      expect(await db.hasRepository(entityDecorator: ProductDecorator()), true);
      expect(await db.hasRepository<Product>(), false);
    });

    test('Test Destroy Repository Wrong Class Name and Key', () async {
      var employeeRepository = await db.getRepository<Employee>();
      expect(employeeRepository, isNotNull);
      expect(await db.hasRepository<Employee>(), true);

      await db.destroyRepository<Employee>(key: 'manager');
      expect(await db.hasRepository<Employee>(), true);
      expect(await db.hasRepository<Employee>(key: 'manager'), false);
    });

    test('Test Has Repository', () async {
      var employeeRepository = await db.getRepository<Employee>();
      var productRepository =
          await db.getRepository(entityDecorator: ProductDecorator());

      expect(employeeRepository, isNotNull);
      expect(productRepository, isNotNull);

      expect(await db.hasRepository<Employee>(), true);
      expect(await db.hasRepository<Employee>(key: 'manager'), false);
      expect(await db.hasRepository(entityDecorator: ProductDecorator()), true);
      expect(
          await db.hasRepository(
              entityDecorator: ProductDecorator(), key: 'ex'),
          false);
    });

    test('Test Update with UniqueConstraint Error', () async {
      var companyRepository = await db.getRepository<Company>();
      var company1 = Company(
          companyId: 1, companyName: 'ABCD', dateCreated: DateTime.now());
      await companyRepository.insert(company1);

      var company2 = Company(companyId: 2, companyName: 'ABCD');

      bool uniqueError = false;
      try {
        await companyRepository.insert(company2);
      } on UniqueConstraintException {
        uniqueError = true;
      } finally {
        expect(uniqueError, true);
      }

      expect(await (companyRepository.find()).length, 1);
    });
  });
}

@GenerateConverter()
@Entity(name: 'entity.employee', indices: [
  Index(fields: ['firstName'], type: IndexType.nonUnique),
  Index(fields: ['lastName'], type: IndexType.nonUnique),
])
class EmployeeEntity with _$EmployeeEntityEntityMixin {
  static final f.Faker faker = f.Faker();
  static int counter = 0;

  @Id(fieldName: 'id')
  int? id;
  String? firstName;
  String? lastName;

  EmployeeEntity() {
    id = counter++;
    firstName = faker.person.firstName();
    lastName = faker.person.lastName();
  }
}
