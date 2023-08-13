import 'dart:math';

import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/nitrite_support.dart';
import 'package:test/test.dart';

import 'base_test_loader.dart';
import 'test_data.dart';

void main() {
  group(retry: 3, 'Import Export With Options Test', () {
    setUp(() async {
      await setUpNitriteTest();
      await populateData();
    });

    tearDown(() async {
      await tearDownNitriteTest();
    });

    test('Test Import Export Single', () async {
      var rnd = Random();
      for (var i = 0; i < 5; i++) {
        await sourceEmpRepo.insert(generateEmployee(generateCompanyRecord()));
        await sourceKeyedEmpRepo
            .insert(generateEmployee(generateCompanyRecord()));

        var doc = createDocument('first-field', rnd.nextDouble());
        await sourceFirstColl.insert(doc);
      }

      await sourceDb.close();
      var exporter = Exporter.withOptions(
        dbFactory: () async => createDb(getTempPath('nitrite_source.db')),
        collections: ['first'],
        repositories: ['Employee'],
        keyedRepositories: {
          'key': {'Employee'},
        },
      );
      await exporter.exportTo(exportedPath);

      var importer = Importer.withConfig(
        dbFactory: () async => createDb(getTempPath('nitrite_dest.db')),
      );
      await importer.importFrom(exportedPath);

      await setUpNitriteTest();

      var destEmpRepo = await destDb.getRepository<Employee>();
      var destKeyedEmpRepo = await destDb.getRepository<Employee>(key: 'key');
      var destFirstColl = await destDb.getCollection('first');

      var sourceDocs = filter(await sourceFirstColl.find().toList());
      var destDocs = filter(await destFirstColl.find().toList());

      expect(sourceDocs, destDocs);

      var sourceEmps = await sourceEmpRepo.find().toList();
      var destEmps = await destEmpRepo.find().toList();
      expect(ListEquality().equals(sourceEmps, destEmps), true);

      var sourceKeyedEmps = await sourceKeyedEmpRepo.find().toList();
      var destKeyedEmps = await destKeyedEmpRepo.find().toList();
      expect(ListEquality().equals(sourceKeyedEmps, destKeyedEmps), true);

      var sourceEmpIndices = await sourceEmpRepo.listIndexes();
      var destEmpIndices = await destEmpRepo.listIndexes();
      expect(
          ListEquality().equals(
              sourceEmpIndices.map((e) => e.toDocument()).toList(),
              destEmpIndices.map((e) => e.toDocument()).toList()),
          true);

      var sourceKeyedEmpIndices = await sourceKeyedEmpRepo.listIndexes();
      var destKeyedEmpIndices = await destKeyedEmpRepo.listIndexes();
      expect(
          ListEquality().equals(
              sourceKeyedEmpIndices.map((e) => e.toDocument()).toList(),
              destKeyedEmpIndices.map((e) => e.toDocument()).toList()),
          true);

      var sourceFirstCollIndices = await sourceFirstColl.listIndexes();
      var destFirstCollIndices = await destFirstColl.listIndexes();
      expect(
          ListEquality().equals(
              sourceFirstCollIndices.map((e) => e.toDocument()).toList(),
              destFirstCollIndices.map((e) => e.toDocument()).toList()),
          true);

      var destCompRepo = await destDb.getRepository<Company>();
      var destSecondColl = await destDb.getCollection('second');

      var destSecondCollDocs = filter(await destSecondColl.find().toList());
      expect(ListEquality().equals(destSecondCollDocs, []), true);

      var destComps = await destCompRepo.find().toList();
      expect(ListEquality().equals(destComps, []), true);

      var destCompIndices = await destCompRepo.listIndexes();
      var sourceCompIndices = await sourceCompRepo.listIndexes();
      expect(
          ListEquality().equals(
              destCompIndices.map((e) => e.toDocument()).toList(),
              sourceCompIndices.map((e) => e.toDocument()).toList()),
          true);

      var destSecondCollIndices = await destSecondColl.listIndexes();
      expect(ListEquality().equals(destSecondCollIndices.toList(), []), true);
    });
  });
}
