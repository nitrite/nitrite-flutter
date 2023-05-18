import 'dart:io';

import 'package:faker/faker.dart' as fk;
import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:test/expect.dart';

import 'data/data_generator.dart';
import 'data/test_objects.dart';
import 'data/test_objects_decorators.dart';

late Nitrite db;
late ObjectRepository<Company> companyRepository;
late ObjectRepository<Employee> employeeRepository;
late ObjectRepository<ClassA> aObjectRepository;
late ObjectRepository<ClassC> cObjectRepository;
late ObjectRepository<Book> bookRepository;
late ObjectRepository<Product> productRepository;
late ObjectRepository<Product> upcomingProductRepository;
late String dbPath;
late fk.Faker faker;

void setUpLog() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: [${record.level.name}] ${record.loggerName} -'
        ' ${record.message}');
    if (record.error != null) {
      print('ERROR: ${record.error}');
    }
  });
}

Future<void> setUpNitriteTest() async {
  await _openDb();

  companyRepository = await db.getRepository<Company>();
  employeeRepository = await db.getRepository<Employee>();
  aObjectRepository = await db.getRepository<ClassA>();
  cObjectRepository = await db.getRepository<ClassC>();
  bookRepository = await db.getRepository<Book>();

  productRepository =
      await db.getRepository<Product>(entityDecorator: ProductDecorator());
  upcomingProductRepository = await db.getRepository<Product>(
      entityDecorator: ProductDecorator(), key: "upcoming");

  for (var i = 0; i < 10; i++) {
    var company = generateCompanyRecord();
    await companyRepository.insert(company);

    var employee = generateEmployee(company);
    employee.empId = i + 1;
    await employeeRepository.insert(employee);

    await aObjectRepository.insert(randomClassA(i + 50));
    await cObjectRepository.insert(randomClassC(i + 50));

    var book = randomBook();
    await bookRepository.insert(book);

    var product = randomProduct();
    await productRepository.insert(product);

    product = randomProduct();
    await upcomingProductRepository.insert(product);
  }

  expect(await companyRepository.size, 10);
  expect(await employeeRepository.size, 10);
  expect(await aObjectRepository.size, 10);
  expect(await cObjectRepository.size, 10);
  expect(await bookRepository.size, 10);
  expect(await productRepository.size, 10);
  expect(await upcomingProductRepository.size, 10);
}

Future<void> cleanUp() async {
  if (!companyRepository.isDropped && companyRepository.isOpen) {
    await companyRepository.remove(all);
    expect(await companyRepository.size, 0);
  }

  if (!employeeRepository.isDropped && employeeRepository.isOpen) {
    await employeeRepository.remove(all);
    expect(await employeeRepository.size, 0);
  }

  if (!aObjectRepository.isDropped && aObjectRepository.isOpen) {
    await aObjectRepository.remove(all);
    expect(await aObjectRepository.size, 0);
  }

  if (!cObjectRepository.isDropped && cObjectRepository.isOpen) {
    await cObjectRepository.remove(all);
    expect(await cObjectRepository.size, 0);
  }

  if (!bookRepository.isDropped && bookRepository.isOpen) {
    await bookRepository.remove(all);
    expect(await bookRepository.size, 0);
  }

  if (!productRepository.isDropped && productRepository.isOpen) {
    await productRepository.remove(all);
    expect(await productRepository.size, 0);
  }

  if (!upcomingProductRepository.isDropped &&
      upcomingProductRepository.isOpen) {
    await upcomingProductRepository.remove(all);
    expect(await upcomingProductRepository.size, 0);
  }

  if (!db.isClosed) {
    await db.commit();
    await db.close();
  }

  var dbFile = File(dbPath);
  await dbFile.delete(recursive: true);
}

Future<void> _openDb() async {
  faker = fk.Faker();
  dbPath = '${Directory.current.path}/db/${faker.guid.guid()}';

  var storeModule =
      HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

  var builder = await Nitrite.builder().loadModule(storeModule);

  db = await builder.fieldSeparator('.').openOrCreate();

  var mapper = db.config.nitriteMapper as SimpleDocumentMapper;
  mapper.registerEntityConverter(CompanyConverter());
  mapper.registerEntityConverter(EmployeeConverter());
  mapper.registerEntityConverter(NoteConverter());
  mapper.registerEntityConverter(MyBookConverter());
  mapper.registerEntityConverter(BookIdConverter());
  mapper.registerEntityConverter(ClassAConverter());
  mapper.registerEntityConverter(ClassBConverter());
  mapper.registerEntityConverter(ClassCConverter());
  mapper.registerEntityConverter(ElemMatchConverter());
  mapper.registerEntityConverter(TextDataConverter());
  mapper.registerEntityConverter(SubEmployeeConverter());
  mapper.registerEntityConverter(ProductScoreConverter());
  mapper.registerEntityConverter(PersonEntityConverter());
  mapper.registerEntityConverter(RepeatableIndexTestConverter());
  mapper.registerEntityConverter(EncryptedPersonConverter());
  mapper.registerEntityConverter(TxDataConverter());
  mapper.registerEntityConverter(WithNitriteIdConverter());
  mapper.registerEntityConverter(ProductConverter());
  mapper.registerEntityConverter(ProductIdConverter());
  mapper.registerEntityConverter(ManufacturerConverter());
  mapper.registerEntityConverter(MiniProductConverter());
  mapper.registerEntityConverter(WithNullIdConverter());
  mapper.registerEntityConverter(NewClassConverter());
  mapper.registerEntityConverter(OldClassConverter());
  mapper.registerEntityConverter(LiteratureConverter());
}
