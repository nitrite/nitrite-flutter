import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'data/data_generator.dart';
import 'data/test_objects.dart';

void main() {
  group("Custom Field Separator Test Suite", () {
    late Nitrite db;
    late ObjectRepository<EmployeeForCustomSeparator> repository;

    setUp(() async {
      db = await Nitrite.builder().fieldSeparator(':').openOrCreate();

      var mapper = db.config.nitriteMapper as SimpleDocumentMapper;
      mapper.registerEntityConverter(CompanyConverter());
      mapper.registerEntityConverter(EmployeeForCustomSeparatorConverter());
      mapper.registerEntityConverter(NoteConverter());

      repository = await db.getRepository<EmployeeForCustomSeparator>();
    });

    tearDown(() async {
      NitriteConfig.fieldSeparator = '.';
      if (!db.isClosed) {
        await db.close();
      }
    });

    test('Test Field Separator', () {
      expect(NitriteConfig.fieldSeparator, ':');
    });

    test('Test Find By Embedded Field', () async {
      var emp1 = EmployeeForCustomSeparator();
      emp1.company = generateCompanyRecord();
      emp1.employeeNote = generateNote();
      emp1.empId = 123;
      emp1.blob = [];
      emp1.address = 'Dummy Address';

      await repository.insert([emp1]);

      var result1 = await repository.find(filter: where('employeeNote.text').eq(null));
      var result2 =
          await repository.find(filter: where('employeeNote:text').notEq(null));

      print(await result1.toList());
      print(await result2.toList());

      // expect(await result1.toList(), isEmpty);
      // expect(await result2.toList(), isNotEmpty);
    });
  });
}
