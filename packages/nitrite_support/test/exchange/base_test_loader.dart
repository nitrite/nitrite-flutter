import 'dart:io';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';

import 'test_data.dart';

late ObjectRepository<Employee> sourceEmpRepo;
late ObjectRepository<Employee> sourceKeyedEmpRepo;
late ObjectRepository<Company> sourceCompRepo;
late NitriteCollection sourceFirstColl;
late NitriteCollection sourceSecondColl;
late Nitrite sourceDb;
late Nitrite destDb;
late String exportedPath;
late String sourceDbPath;
late String destDbPath;

String getTempPath(String name) =>
    '${Directory.current.path}${Platform.pathSeparator}build'
    '${Platform.pathSeparator}test_path${Platform.pathSeparator}$name';

Future<void> setUpNitriteTest() async {
  sourceDbPath = getTempPath('nitrite_source.db');
  destDbPath = getTempPath('nitrite_dest.db');
  exportedPath = getTempPath('nitrite_export.json');

  sourceDb = await createDb(sourceDbPath);
  destDb = await createDb(destDbPath);

  sourceEmpRepo = await sourceDb.getRepository<Employee>();
  sourceKeyedEmpRepo = await sourceDb.getRepository<Employee>(key: 'key');
  sourceCompRepo = await sourceDb.getRepository<Company>();

  sourceFirstColl = await sourceDb.getCollection('first');
  sourceSecondColl = await sourceDb.getCollection('second');
}

Future<void> populateData() async {
  for (var i = 0; i < 10; i++) {
    var company = generateCompanyRecord();
    await sourceCompRepo.insert(company);

    var employee = generateEmployee(company);
    employee.empId = i + 1;
    await sourceEmpRepo.insert(employee);
  }
}

Future<Nitrite> createDb(String dbFile) async {
  var storeModule =
      HiveModule.withConfig().crashRecovery(true).path(dbFile).build();

  var documentMapper = EntityConverterMapper()
    ..registerEntityConverter(EmployeeConverter())
    ..registerEntityConverter(CompanyConverter())
    ..registerEntityConverter(NoteConverter());

  return await Nitrite.builder()
      .loadModule(storeModule)
      .loadModule(module([documentMapper]))
      .fieldSeparator('.')
      .openOrCreate();
}

Future<void> tearDownNitriteTest() async {
  if (!sourceDb.isClosed) {
    await sourceDb.close();
  }

  if (!destDb.isClosed) {
    await destDb.close();
  }

  var sourceDbFile = File(sourceDbPath);
  await sourceDbFile.delete(recursive: true);

  var destDbFile = File(destDbPath);
  await destDbFile.delete(recursive: true);

  var exportedFile = File(exportedPath);
  await exportedFile.delete(recursive: true);
}

List<Document> filter(List<Document> documents) {
  return documents
      .map((doc) => doc
        ..remove(docRevision)
        ..remove(docModified)
        ..remove(docSource))
      .toList();
}
