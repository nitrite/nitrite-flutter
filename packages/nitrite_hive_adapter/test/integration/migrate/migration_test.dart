import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/src/store/index.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../repository/base_object_repository_test_loader.dart';
import '../repository/data/test_objects.dart';

void main() {
  group('Migration Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Repository Migrate', () async {
      var oldRepo = await db.getRepository<OldClass>(key: 'demo1');
      for (var i = 0; i < 10; i++) {
        var oldClass = OldClass();
        oldClass.empId = faker.randomGenerator.integer(100).toString();
        oldClass.firstName = faker.person.firstName();
        oldClass.lastName = faker.person.lastName();
        oldClass.uuid = Uuid().v4();

        var literature = Literature();
        literature.ratings = faker.randomGenerator.decimal();
        literature.text = faker.lorem.sentence();
        oldClass.literature = literature;

        await oldRepo.insert([oldClass]);
      }

      var keyedRepos = (await db.listKeyedRepositories).length;
      print('Keyed Repositories Before: ${(await db.listKeyedRepositories)}');

      var nitriteMapper = db.config.nitriteMapper;
      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet
              .forDatabase()
              .addPassword('test-user', 'test-password');

          instructionSet
              .forRepository<OldClass>(key: 'demo1')
              .renameRepository('new')
              .changeDataType('empId', (value) => int.parse(value))
              .changeIdField(
                  Fields.withNames(['uuid']), Fields.withNames(['empId']))
              .deleteField('uuid')
              .renameField('lastName', 'familyName')
              .addField(
                'fullName',
                generator: (document) =>
                    '${document['firstName']} ${document['familyName']}',
              )
              .dropIndex(['firstName']).dropIndex([
            'literature.text'
          ]).changeDataType(
                  'literature.ratings', (value) => (value as double).round());
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();
      var builder = await Nitrite.builder()
          .loadModule(NitriteModule.module([nitriteMapper]));

      await builder.loadModule(storeModule);

      db = await builder
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate(
              username: 'test-user', password: 'test-password');

      var newRepo = await db.getRepository<NewClass>();
      expect(await newRepo.size, 10);
      expect(await db.listCollectionNames, isEmpty);

      print('Keyed Repositories After: ${(await db.listKeyedRepositories)}');

      var keyedRepos2 = (await db.listKeyedRepositories).length;
      expect(keyedRepos2, keyedRepos - 1);
      expect((await db.databaseMetaData).schemaVersion, 2);
    });
  });
}
