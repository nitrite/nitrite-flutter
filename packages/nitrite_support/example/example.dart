import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:nitrite_support/nitrite_support.dart';

void main(List<String> args) async {
  // export the database to a json file
  var exporter = Exporter.withOptions(
    dbFactory: () async {
      var storeModule = HiveModule.withConfig()
          .crashRecovery(true)
          .path('/tmp/old-db')
          .build();

      return Nitrite.builder()
          .loadModule(storeModule)
          .openOrCreate(username: 'user', password: 'pass123');
    },
    collections: ['first'],
    repositories: ['Employee'],
    keyedRepositories: {
      'key': {'Employee'},
    },
  );
  await exporter.exportTo('/tmp/exported.json');

  // import the database from the json file
  var importer = Importer.withOptions(
    dbFactory: () async {
      var storeModule = HiveModule.withConfig()
          .crashRecovery(true)
          .path('/tmp/new-db')
          .build();

      return Nitrite.builder().loadModule(storeModule).openOrCreate();
    },
  );
  await importer.importFrom('/tmp/exported.json');
}
