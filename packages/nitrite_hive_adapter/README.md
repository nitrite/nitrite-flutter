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

Construct the `HiveModule` and open the database **inside** the isolate. Data
written on a background isolate persists and can be reopened on any isolate.

### Sharing one database across many isolates

A Hive file must not be opened by more than one isolate at the same time —
independent in-memory state would diverge and concurrent writes would corrupt
the file. To let several isolates read and write the **same** database, run it
on a single *owner* isolate with `NitriteIsolate` (from the core package) and
share the handle; every operation is serialised through the owner:

```dart
// open once on an owner isolate (openMyDb is a top-level function)
final db = await NitriteIsolate.spawn(openMyDb);

// the handle is sendable — hand it to as many workers as you like
await Future.wait([
  Isolate.run(() => db.getCollection('events').insert([doc])),
  Isolate.run(() => db.getCollection('events').find(filter: where('type').eq('click'))),
]);

await db.close();
```

`IsolateCollection` proxies `insert`, `find`, `getById`, `size`, `update`,
`remove` and `createIndex`; documents, filters and ids cross the isolate
boundary by value, so `find` returns a materialised list rather than a live
cursor. Typed repositories are not proxied (their converters live in the owner
isolate) — use document collections.

## Additional information

For additional information visit the Hive module [documentation](https://nitrite.dizitart.com/flutter-sdk/modules/store-modules/hive/index.html).
