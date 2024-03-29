# Nitrite Database

[![Build Nitrite](https://github.com/nitrite/nitrite-flutter/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/nitrite/nitrite-flutter/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/nitrite/nitrite-flutter/branch/main/graph/badge.svg?token=yqfI3tbHqp)](https://codecov.io/gh/nitrite/nitrite-flutter)
[![Discussion](https://img.shields.io/badge/chat-Discussion-blueviolet)](https://github.com/orgs/nitrite/discussions)

<p align="center">
    <img src="assets/nitrite-logo.svg" width="256" alt="nitrite logo">
</p>

**NO**sql **O**bject (**NO<sub>2</sub>** a.k.a. Nitrite) database is an open source nosql embedded
document store. It supports both in-memory and file based persistent store.

Nitrite is an embedded database ideal for desktop, mobile or small web applications.

**It features**:

-   Embedded, serverless
-   Simple API
-   Document-oriented
-   Schemaless document collection and object repository
-   Extensible storage engines - hive
-   Indexing and full-text search
-   Simple query api
-   In-memory and file-based store
-   Transaction support
-   Schema migration support
-   Encryption support

## Java Version

If you are looking for Nitrite for java, head over to [nitrite-java](https://github.com/nitrite/nitrite-java).

## Getting Started with Nitrite

### How To Install

To use Nitrite in any Flutter application, add the below packages in your project:

```bash
dart pub add nitrite
dart pub add nitrite_hive_adapter
```

## Examples

A Todo flutter application is available [here](https://github.com/nitrite/nitrite-flutter/tree/main/examples/nitrite_demo). It demonstrates the use of nitrite database in a flutter application. It uses nitrite as a database and riverpod for state management.

### Quick Examples

**Initialize Database**

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

**Create a Collection/ObjectRepository**

```dart
// Create a Nitrite Collection
var collection = await db.getCollection("test");

// Create an Object Repository
var repository = await db.getRepository<Book>();

```

**Code generators for Entity classes**

The nitrite generator package can automatically generate entity classes from dart classes. It uses [source_gen](https://pub.dev/packages/source_gen) package to generate code. To use the generator, add the following packages to your project:

```bash
dart pub add nitrite_generator --dev
dart pub add build_runner --dev
```

Use below annotations in your dart classes:

```dart
import 'package:nitrite/nitrite.dart';

part 'book.no2.dart';

@Convertable(className: 'MyBookConverter')
@Entity(name: 'books', indices: [
  Index(fields: ['tags'], type: IndexType.nonUnique),
  Index(fields: ['description'], type: IndexType.fullText),
  Index(fields: ['price', 'publisher']),
])
class Book with _$BookEntityMixin {
  // id field
  @Id(fieldName: 'book_id', embeddedFields: ['isbn', 'book_name'])
  @DocumentKey(alias: 'book_id')
  BookId? bookId;

  String? publisher;
  double? price;
  List<String> tags = [];
  String? description;

  Book([
    this.bookId,
    this.publisher,
    this.price,
    this.tags = const [],
    this.description,
  ]);
  
}

// composite id class
@Convertable()
class BookId {
  String? isbn;

  // set a different field name in the document
  @DocumentKey(alias: "book_name")
  String? name;

  // ignore the field in the document
  @IgnoredKey()
  String? author;
}

```

And run the following command to generate necessary *.no2.dart files:

```bash
dart run build_runner build
```

**CRUD Operations**

```dart

// create a document to populate data
var doc = createDocument("firstName", "fn1")
    .put("lastName", "ln1")
    .put("birthDay", DateTime.parse("2012-07-01T16:02:48.440Z"))
    .put("data", [1, 2, 3])
    .put("list", ["one", "two", "three"])
    .put("body", "a quick brown fox jump over the lazy dog")
    .put("books", [
      createDocument("name", "Book ABCD").put("tag", ["tag1", "tag2"]),
      createDocument("name", "Book EFGH").put("tag", ["tag3", "tag1"]),
      createDocument("name", "No Tag")
    ]);

// insert the document
await collection.insert(doc);

// find documents from the collection
var cursor = collection.find(filter: and([
      where('lastName').eq('ln1'),
      where("firstName").notEq("fn1"),
      where("list").eq("four"),
    ]),
);

// update the document
await collection.update(
  where('firstName').eq('fn1'),
  createDocument('firstName', 'fn1-updated'),
  updateOptions(insertIfAbsent: true),
);

// remove the document
await coll.remove(where('firstName').eq('fn1-updated'));

// insert an object in repository
var bookId = BookId();
bookId.isbn = 'abc123';
bookId.author = 'xyz';
bookId.name = 'Book 1';

var book = Book();
book.bookId = bookId;
book.tags = ['tag1', 'tag2'];
book.description = 'A book about nitrite database';
book.publisher = 'rando publisher';
book.price = 150.5;

await repository.insert(book);

```

**Create Indices**

```dart

// create document index
await collection.createIndex(['firstName', 'lastName']); // unique index
await collection.createIndex(['firstName'], indexOptions(IndexType.nonUnique))

// create object index. It can also be provided via annotation
await repository.createIndex("publisher", indexOptions(IndexType.NonUnique));

```

**Query a Collection**

```dart

var cursor = collection.find(
  filter: and([
    where('lastName').eq('ln2'),
    where("firstName").notEq("fn1"),
    where("list").eq("four")
  ]),
);

await for (var d in cursor) {
  print(d);
}

// get document by a nitrite id
var document = await collection.getById(nitriteId);

// query an object repository and create the first result
var cursor = repository.find(
    filter: where('book_id.isbn').eq('abc123'),
);
var book = await cursor.first();

```


**Transaction**

Nitrite has support for transaction. Transaction is supported only for file based storage.

```dart
var session = db.createSession();
var tx = await session.beginTransaction();

var txRepo = await tx.getRepository<Book>();
await txRepo.insert(book);
await tx.commit();

```
or, another way to do the same thing:

```dart
var session = db.createSession();
await session.executeTransaction((tx) async {
  var txRepo = await tx.getRepository<Book>();
  await txRepo.insertMany([book1, book2, book3]);
});

```

**Schema Migration**

Nitrite supports schema migration. It can be used to migrate data from one schema version to another. It is useful when you want to change the schema of your application without losing the existing data.

```dart

var migration = Migration(
  3,
  4,
  (instructionSet) {
    instructionSet
        .forCollection('test')
        .addField('age', defaultValue: 10);
  },
);

db = await Nitrite.builder()
      .loadModule(storeModule)
      .schemaVersion(4)
      .addMigrations([migration])
      .openOrCreate();

```


**Import/Export Data**

```dart
// Export data to a file
var exporter = Exporter.withOptions(
  dbFactory: () async {
    var storeModule = HiveModule.withConfig()
    .crashRecovery(true)
    .path('$dbDir/old-db')
    .build();

    return Nitrite.builder()
    .loadModule(storeModule)
    .openOrCreate(username: 'user', password: 'pass123');
  },
);
await exporter.exportTo(exportedPath);

//Import data from the file
var importer = Importer.withConfig(
  dbFactory: () async {
    var storeModule = HiveModule.withConfig()
    .crashRecovery(true)
    .path('$dbDir/new-db')
    .build();

    return Nitrite.builder()
    .loadModule(storeModule)
    .openOrCreate();
  },
);
await importer.importFrom(exportedPath);

```

More details are available in the reference document.

## Release Notes

Release notes are available [here](https://github.com/nitrite/nitrite-flutter/releases).

## Documentation

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th>Reference</th>
<th>API</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><a href="https://nitrite.dizitart.com/flutter-sdk/getting-started/index.html">Document</a></p></td>
<td><p><a href="https://pub.dev/documentation/nitrite/latest">API Reference</a></p></td>
</tr>
</tbody>
</table>

## Build

To build and test Nitrite, you need to install melos. Melos is a CLI tool to manage Dart projects with multiple packages. It is similar to Lerna for JavaScript/TypeScript projects. Visit [melos](https://melos.invertase.dev/) for more details to setup your system.


```shell script

melos bs
melos run test

```

## Bugs / Feature Requests

Think you’ve found a bug? Want to see a new feature in the Nitrite? Please open an issue [here](https://github.com/nitrite/nitrite-flutter/issues). But
before you file an issue please check if it is already existing or not.

## Maintainers

-   Anindya Chatterjee

## Contributing

Do you want to contribute with a PR? PRs are always welcome, just make sure to create a [discussion](https://github.com/nitrite/nitrite-flutter/discussions) first to avoid any unnecessary work.

## Special Thanks
  
<a href="https://www.macstadium.com/" style="margin-right: 30px;">
    <img src="https://uploads-ssl.webflow.com/5ac3c046c82724970fc60918/5c019d917bba312af7553b49_MacStadium-developerlogo.png" height="32" alt="MacStadium"/>
</a>

