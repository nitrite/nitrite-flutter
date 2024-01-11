# Nitrite Hive Adapter

Nitrite Hive adapter uses [Hive](https://pub.dev/packages/hive) as a file based storage engine for Nitrite database.

## Getting started

To use Hive as a storage engine for Nitrite, add the following dependency in your project:

```bash
dart pub add nitrite_hive_adapter
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

For additional information visit the Hive module [documentation](https://nitrite.dizitart.com/flutter-sdk/modules/store-modules/hive/index.html).
