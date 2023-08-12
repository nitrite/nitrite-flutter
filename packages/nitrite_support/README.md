# Nitrite Support

A support library for Nitrite database to import/export data as a json file.

## Getting started

To use Nitrite support, add the following dependency in your `pubspec.yaml` file:

```yaml

dependencies:
  nitrite_support: ^[version]

```

## Usage

### Exporting data

To export data from a Nitrite database, you can use the `Exporter` class.

```dart
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

```


### Importing data

To import data to a Nitrite database, you can use the `Importer` class.

```dart

var importer = Importer.withConfig(
    dbFactory: () async {
        var storeModule = HiveModule.withConfig()
            .crashRecovery(true)
            .path('/tmp/new-db')
            .build();

        return Nitrite.builder().loadModule(storeModule).openOrCreate();
    },
);

await importer.importFrom('/tmp/exported.json');

```