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

## Running on a background isolate

Nitrite has no dependency on the main UI isolate or platform channels — the
database path is supplied by you (it never calls `path_provider`), so a Hive
backed database can be opened and used entirely on a background isolate to keep
heavy database work off the UI thread:

```dart
// runs on a background isolate via Isolate.run / compute
final count = await Isolate.run(() async {
  final module = HiveModule.withConfig().path('$dbDir/db').build();
  final db = await Nitrite.builder().loadModule(module).openOrCreate();
  final col = await db.getCollection('events');
  // ... heavy inserts / queries ...
  final c = await col.find(filter: where('type').eq('click')).count();
  await db.close();
  return c;
});
```

Construct the `HiveModule` and open the database **inside** the isolate, and
let a single isolate own a given database path at a time (Hive boxes are not
safe for concurrent access to the same file from multiple isolates). Data
written on a background isolate persists and can be reopened on any isolate.

## Additional information

For additional information visit the Hive module [documentation](https://nitrite.dizitart.com/flutter-sdk/modules/store-modules/hive/index.html).
