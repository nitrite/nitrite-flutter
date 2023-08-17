import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/data_generator.dart';
import 'data/test_objects.dart';

void main() {
  late Nitrite db;
  late ObjectRepository<EmployeeForCustomSeparator> repository;

  group(retry: 3, "Custom Field Separator Test Suite", () {
    setUp(() async {
      setUpLog();

      db = await Nitrite.builder().fieldSeparator(':').openOrCreate();

      var mapper = db.config.nitriteMapper as SimpleNitriteMapper;
      mapper.registerEntityConverter(CompanyConverter());
      mapper.registerEntityConverter(EmployeeForCustomSeparatorConverter());
      mapper.registerEntityConverter(NoteConverter());

      repository = await db.getRepository<EmployeeForCustomSeparator>();
      await repository.clear();
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
      expect(await repository.hasIndex(['joinDate']), true);
      expect(await repository.hasIndex(['address']), true);
      expect(await repository.hasIndex(['employeeNote:text']), true);

      var emp1 = EmployeeForCustomSeparator();
      emp1.company = generateCompanyRecord();
      emp1.employeeNote = Note(noteId: 567, text: 'Dummy Note');
      emp1.empId = 123;
      emp1.blob = [];
      emp1.address = 'Dummy Address';

      await repository.insert(emp1);

      var cursor1 =
          repository.find(filter: where('employeeNote.text').eq('Dummy Note'));
      var cursor2 = repository.find(
          filter: where('employeeNote:text').text('Dummy Note'));

      expect(await cursor1.length, 0);
      expect(await cursor2.length, 1);
    });
  });
}
