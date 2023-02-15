import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';

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
    await companyRepository.insert([company]);

    var employee = generateEmployee(company);
    employee.empId = i + 1;
    employeeRepository.insert([employee]);

    aObjectRepository.insert([randomClassA(i + 50)]);
    cObjectRepository.insert([randomClassC(i + 50)]);

    var book = randomBook();
    bookRepository.insert([book]);

    var product = randomProduct();
    productRepository.insert([product]);

    product = randomProduct();
    upcomingProductRepository.insert([product]);
  }
}

Future<void> cleanUp() async {
  if (!companyRepository.isDropped) {
    await companyRepository.remove(all);
  }

  if (!employeeRepository.isDropped) {
    await employeeRepository.remove(all);
  }

  if (!aObjectRepository.isDropped) {
    await aObjectRepository.remove(all);
  }

  if (!cObjectRepository.isDropped) {
    await cObjectRepository.remove(all);
  }

  if (!bookRepository.isDropped) {
    await bookRepository.remove(all);
  }

  if (!productRepository.isDropped) {
    await productRepository.remove(all);
  }

  if (!upcomingProductRepository.isDropped) {
    await upcomingProductRepository.remove(all);
  }

  if (!db.isClosed) {
    await db.commit();
    await db.close();
  }
}

Future<void> _openDb() async {
  var nitriteBuilder = Nitrite.builder().fieldSeparator('.');
  db = await nitriteBuilder.openOrCreate(
      username: 'test-user', password: 'test-password');

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
}
