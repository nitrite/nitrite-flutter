import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/src/store/index.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../test_utils.dart';
import '../repository/base_object_repository_test_loader.dart';
import '../repository/data/test_objects.dart';

void main() {
  group(retry: 3, 'Migration Test Suite', () {
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
        oldClass.empId = '${i + 1}';
        oldClass.firstName = faker.person.firstName();
        oldClass.lastName = faker.person.lastName();
        oldClass.uuid = Uuid().v4();

        var literature = Literature();
        literature.ratings = faker.randomGenerator.decimal();
        literature.text = faker.lorem.sentence();
        oldClass.literature = literature;

        await oldRepo.insert(oldClass);
      }

      var keyedRepos = (await db.listKeyedRepositories).length;
      var nitriteMapper = db.config.nitriteMapper;
      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet.forDatabase().addUser('test-user', 'test-password');

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

      db = await Nitrite.builder()
          .loadModule(module([nitriteMapper]))
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate(
              username: 'test-user', password: 'test-password');

      var newRepo = await db.getRepository<NewClass>();
      expect(await newRepo.size, 10);
      expect(await db.listCollectionNames, isEmpty);

      var keyedRepos2 = (await db.listKeyedRepositories).length;
      expect(keyedRepos2, keyedRepos - 1);
      expect((await db.databaseMetaData).schemaVersion, 2);
    });

    test('Test Collection Migrate', () async {
      var collection = await db.getCollection('test');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName())
          ..put('bloodGroup', faker.randomGenerator.fromCharSet('ABO', 1))
          ..put('age', faker.randomGenerator.integer(100));

        await collection.insert(document);
      }

      await collection
          .createIndex(['firstName'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['bloodGroup'], indexOptions(IndexType.nonUnique));
      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet.forDatabase().addUser('test-user', 'test-password');

          instructionSet
              .forCollection('test')
              .rename('testCollectionMigrate')
              .deleteField('lastName');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate(
              username: 'test-user', password: 'test-password');

      collection = await db.getCollection('testCollectionMigrate');
      expect(await collection.size, 10);
      expect(await collection.hasIndex(['firstName']), isTrue);
      expect(await collection.hasIndex(['bloodGroup']), isTrue);
      expect(await db.listCollectionNames, hasLength(1));
      expect((await db.databaseMetaData).schemaVersion, 2);

      await db.close();

      migration = Migration(2, 3, (instructionSet) {
        instructionSet
            .forDatabase()
            .changePassword('test-user', 'test-password', 'password');

        instructionSet
            .forCollection('testCollectionMigrate')
            .dropIndex(['firstName'])
            .deleteField('bloodGroup')
            .addField('name', generator: (document) => faker.person.name())
            .addField('address')
            .addField('vehicles', defaultValue: 1)
            .renameField('age', 'ageGroup')
            .createIndex(IndexType.nonUnique, ['ageGroup']);
      });

      storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(3)
          .addMigrations([migration]).openOrCreate(
              username: 'test-user', password: 'password');

      collection = await db.getCollection('testCollectionMigrate');
      expect(await collection.size, 10);
      expect(await collection.hasIndex(['firstName']), isFalse);
      expect(await collection.hasIndex(['bloodGroup']), isFalse);
      expect(await collection.hasIndex(['ageGroup']), isTrue);
      expect(await db.listCollectionNames, hasLength(1));
      expect((await db.databaseMetaData).schemaVersion, 3);

      var cursor = collection.find(filter: where('age').notEq(null));
      expect(await cursor.length, 0);
    });

    test('Test Open Without Schema Version', () async {
      var collection = await db.getCollection('test');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName());

        await collection.insert(document);
      }

      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet
              .forCollection('test')
              .rename('testOpenWithoutSchemaVersion')
              .deleteField('lastName');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testOpenWithoutSchemaVersion');
      expect(await collection.size, 10);

      await db.close();

      storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      expect(
          () async => await Nitrite.builder()
              .loadModule(storeModule)
              .fieldSeparator('.')
              .addMigrations([migration]).openOrCreate(),
          throwsMigrationException);
    });

    test('Test Descending Schema', () async {
      var collection = await db.getCollection('test');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName());

        await collection.insert(document);
      }

      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet
              .forCollection('test')
              .rename('testDescendingSchema')
              .deleteField('lastName');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testDescendingSchema');
      expect(await collection.size, 10);

      await db.close();

      migration = Migration(
        2,
        1,
        (instructionSet) {
          instructionSet.forCollection('testDescendingSchema').rename('test');
        },
      );

      storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(1)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('test');
      expect(await collection.size, 10);

      await db.close();
    });

    test('Test Migration Without Version', () async {
      var collection = await db.getCollection('test');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName());

        await collection.insert(document);
      }

      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet
              .forCollection('test')
              .rename('testMigrationWithoutVersion')
              .deleteField('lastName');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testMigrationWithoutVersion');
      expect(await collection.size, 0);

      collection = await db.getCollection('test');
      expect(await collection.size, 10);

      await db.close();
    });

    test('Test Wrong Schema Version No Migration', () async {
      var collection =
          await db.getCollection('testWrongSchemaVersionNoMigration');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName());

        await collection.insert(document);
      }

      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet
              .forCollection('testWrongSchemaVersionNoMigration')
              .rename('test')
              .deleteField('lastName');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testWrongSchemaVersionNoMigration');
      expect(await collection.size, 0);

      collection = await db.getCollection('test');
      expect(await collection.size, 10);
      await db.close();

      migration = Migration(
        2,
        3,
        (instructionSet) {
          instructionSet
              .forCollection('test')
              .rename('testWrongSchemaVersionNoMigration');
        },
      );

      storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testWrongSchemaVersionNoMigration');
      expect(await collection.size, 0);

      collection = await db.getCollection('test');
      expect(await collection.size, 10);

      await db.close();
    });

    test('Test Reopen After Migration', () async {
      var collection = await db.getCollection('testReOpenAfterMigration');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName());

        await collection.insert(document);
      }

      await db.close();

      var migration = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet
              .forCollection('testReOpenAfterMigration')
              .rename('test')
              .deleteField('lastName');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testReOpenAfterMigration');
      expect(await collection.size, 0);

      collection = await db.getCollection('test');
      expect(await collection.size, 10);
      await db.close();

      storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration]).openOrCreate();

      collection = await db.getCollection('testReOpenAfterMigration');
      expect(await collection.size, 0);

      collection = await db.getCollection('test');
      expect(await collection.size, 10);

      await db.close();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .openOrCreate();

      collection = await db.getCollection('testReOpenAfterMigration');
      expect(await collection.size, 0);

      collection = await db.getCollection('test');
      expect(await collection.size, 10);
    });

    test('Test Multiple Migrations', () async {
      var collection = await db.getCollection('testMultipleMigrations');
      for (var i = 0; i < 10; i++) {
        var document = emptyDocument()
          ..put('firstName', faker.person.firstName())
          ..put('lastName', faker.person.lastName());

        await collection.insert(document);
      }

      await db.close();

      var migration1 = Migration(
        initialSchemaVersion,
        2,
        (instructionSet) {
          instructionSet.forCollection('testMultipleMigrations').rename('test');
        },
      );

      var migration2 = Migration(
        2,
        3,
        (instructionSet) {
          instructionSet
              .forCollection('test')
              .addField('fullName', defaultValue: 'Dummy Name');
        },
      );

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(2)
          .addMigrations([migration1, migration2]).openOrCreate();

      collection = await db.getCollection('test');
      expect(await collection.size, 10);

      var cursor = collection.find(filter: where('fullName').eq('Dummy Name'));
      expect(await cursor.length, 0);
      await db.close();

      var migration3 = Migration(
        3,
        4,
        (instructionSet) {
          instructionSet
              .forCollection('test')
              .addField('age', defaultValue: 10);
        },
      );

      storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .schemaVersion(4)
          .addMigrations([migration1, migration2, migration3]).openOrCreate();

      collection = await db.getCollection('test');
      expect(await collection.size, 10);

      cursor = collection.find(filter: where('fullName').eq('Dummy Name'));
      expect(await cursor.length, 10);

      cursor = collection.find(filter: where('age').eq(10));
      expect(await cursor.length, 10);
    });
  });
}
