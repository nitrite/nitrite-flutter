# Nitrite Database

<img src="http://www.dizitart.org/nitrite-database/logo/nitrite-logo.svg" alt="Logo" width="200"/>

**NO**sql **O**bject (**NO<sub>2</sub>** a.k.a. Nitrite) database is an open source nosql embedded
document store. It supports both in-memory and file based persistent store.

Nitrite is an embedded database ideal for desktop, mobile or small web applications.

**It features**:

-   Embedded, serverless
-   Simple API
-   Document-oriented
-   Schemaless document collection and object repository
-   Indexing and full-text search
-   Simple query api
-   In-memory store
-   Transaction support
-   Schema migration support
-   Encryption support


## Getting Started with Nitrite

### How To Install

To use Nitrite in any Flutter application, add the below in your `pubspec.yaml` file:

```yaml
dependencies:
  nitrite: ^[version]

dev_dependencies:
  build_runner: ^2.4.6
  nitrite_generator: ^[version]

```

### Quick Examples

**Initialize Database**

```dart
// initialization Nitrite database with in-memory store
var db = await Nitrite.builder()
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

The nitrite entity generator package can automatically generate entity classes from dart classes. It uses [source_gen](https://pub.dev/packages/source_gen) package to generate code. To use the generator, add the following to your `pubspec.yaml` file:

```yaml

dev_dependencies:
  nitrite_generator: ^[version]

```

And use below annotations in your dart classes:

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

More details are available in the reference [document](https://nitrite.dizitart.com/flutter-sdk/getting-started/index.html).