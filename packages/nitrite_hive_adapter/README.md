# Nitrite Hive Adapter

Nitrite Hive adapter uses [Hive](https://pub.dev/packages/hive) as a file based storage engine for Nitrite database.

## Getting started

To use Hive as a storage engine for Nitrite, add the following dependency in your `pubspec.yaml` file:

```yaml

dependencies:
  nitrite_hive_adapter: ^[version]

```

## Usage

To use Hive as a storage engine, you need to create a `HiveModule` and pass it to Nitrite builder. 

```dart
// create a hive backed storage module
var storeModule = HiveModule.withConfig()
    .crashRecovery(true)
    .path('$dbDir/db')
    .build();

// initialization using builder
var db = await Nitrite.builder()
    .loadModule(storeModule)
    .openOrCreate(username: 'user', password: 'pass123');

```

## Additional information

For additional information visit the reference documentation: [https://www.dizitart.org/nitrite-database](https://www.dizitart.org/nitrite-database)
