import 'dart:math';

import 'package:collection/collection.dart';
import 'package:faker/faker.dart';
import 'package:nitrite/nitrite.dart';

part 'nitrite_example.no2.dart';

void main() async {
  // Create a Nitrite database
  var db = await createDatabase();

  // Perform collection operations
  await collectionExample(db);

  // Perform object repository operations
  await objectRepositoryExample(db);

  // Perform transaction operations
  await transactionExample(db);

  // Close the database
  await db.close();
}

Future<Nitrite> createDatabase() async {
  // Creates an in-memory database with default options
  var db = await Nitrite.builder().openOrCreate();
  return db;
}

Future<void> collectionExample(Nitrite db) async {
  // Get a Nitrite collection
  var coll = await db.getCollection('test');

  // Create documents
  var doc1 = createDocument("firstName", "fn1")
      .put("lastName", "ln1")
      .put("birthDay", DateTime.parse("2012-07-01T16:02:48.440Z"))
      .put("data", [1, 2, 3])
      .put("list", ["one", "two", "three"])
      .put("body", "a quick brown fox jump over the lazy dog")
      .put("books", [
        createDocument("name", "Book ABCD")..put("tag", ["tag1", "tag2"]),
        createDocument("name", "Book EFGH")..put("tag", ["tag3", "tag1"]),
        createDocument("name", "No Tag")
      ]);

  var doc2 = createDocument("firstName", "fn2")
      .put("lastName", "ln2")
      .put("birthDay", DateTime.parse("2010-06-12T16:02:48.440Z"))
      .put("data", [3, 4, 3])
      .put("list", ["three", "four", "five"])
      .put("body", "quick hello world from nitrite")
      .put("books", [
        createDocument("name", "Book abcd")..put("tag", ["tag4", "tag5"]),
        createDocument("name", "Book wxyz")..put("tag", ["tag3", "tag1"]),
        createDocument("name", "No Tag 2")
      ]);

  var doc3 = createDocument("firstName", "fn3")
      .put("lastName", "ln2")
      .put("birthDay", DateTime.parse("2014-04-17T16:02:48.440Z"))
      .put("data", [9, 4, 8])
      .put(
          "body",
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nunc mi, '
              'mattis ullamcorper dignissim vitae, condimentum non lorem.')
      .put("books", [
        createDocument("name", "Book Mnop")..put("tag", ["tag6", "tag2"]),
        createDocument("name", "Book ghij")..put("tag", ["tag3", "tag7"]),
        createDocument("name", "No Tag")
      ]);

  // Insert a document
  await coll.insert(doc1);

  // Insert multiple documents
  await coll.insertMany([doc2, doc3]);

  // Create an index on firstName
  await coll.createIndex(['firstName']);

  // Create full text index on body
  await coll.createIndex(['body'], indexOptions(IndexType.fullText));

  // Create index on book tags
  await coll.createIndex(['books.tag'], indexOptions(IndexType.nonUnique));

  // Find all documents
  var cursor = coll.find(filter: where('firstName').eq('fn1'));
  print('First document where firstName is fn1: ${await cursor.toList()}');

  cursor = coll.find(filter: where('body').text('Lorem'));
  print('Documents where body contains Lorem: ${await cursor.toList()}');

  cursor = coll.find(filter: where('books.tag').eq('tag2'));
  print('Documents where books.tag is tag2: ${await cursor.toList()}');

  // Drop all indices
  await coll.dropAllIndices();

  // Create compound index on list, lastName and firstName
  await coll.createIndex(['list', 'lastName', 'firstName']);
  cursor = coll.find(
    filter: and([
      where('lastName').eq('ln2'),
      where("firstName").notEq("fn1"),
      where("list").eq("four"),
    ]),
  );
  print('Documents where lastName is ln2, firstName is not fn1 and list contains'
      ' four: ${await cursor.toList()}');

  // get the find plan
  var findPlan = await cursor.findPlan;
  print(findPlan);

  // clear the collection
  await coll.clear();

  // drop the collection
  await coll.drop();
}

Future<void> objectRepositoryExample(Nitrite db) async {
  // Register converters
  var nitriteMapper = db.config.nitriteMapper as SimpleDocumentMapper;
  nitriteMapper.registerEntityConverter(MyBookConverter());
  nitriteMapper.registerEntityConverter(BookIdConverter());

  // Get a repository
  var repo = await db.getRepository<Book>();

  // Create a book
  var book = randomBook();

  // Insert a book
  await repo.insert(book);

  // Insert multiple books
  await repo.insertMany([randomBook(), randomBook(), randomBook()]);

  // Find all books
  var cursor = repo.find();
  print('All books: ${await cursor.toList()}');

  // Find books by tags
  cursor = repo.find(filter: where('tags').eq('tag2'));
  print('Books where tags is tag2: ${await cursor.toList()}');

  // Find books by description
  cursor = repo.find(filter: where('description').text('lorem'));
  print('Books where description contains lorem: ${await cursor.toList()}');

  // Find books by price and publisher
  cursor = repo.find(filter: and([
    where('price').gt(100),
    where('publisher').eq('publisher1'),
  ]));
  print('Books where price is greater than 100 and publisher is publisher1: '
      '${await cursor.toList()}');

  // clear the repository
  await repo.clear();

  // drop the repository
  await repo.drop();
}

Future<void> transactionExample(Nitrite db) async {

}

// ==============================================================
// Entity classes
// ==============================================================
@GenerateConverter(className: 'MyBookConverter')
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          publisher == other.publisher &&
          price == other.price &&
          ListEquality().equals(tags, other.tags) &&
          description == other.description;

  @override
  int get hashCode =>
      bookId.hashCode ^
      publisher.hashCode ^
      price.hashCode ^
      ListEquality().hash(tags) ^
      description.hashCode;

  @override
  String toString() {
    return 'Book{'
        'bookId: $bookId, '
        'publisher: $publisher, '
        'price: $price, '
        'tags: $tags, '
        'description: $description'
        '}';
  }
}

// composite id class
@GenerateConverter()
class BookId {
  String? isbn;

  // set a different field name in the document
  @DocumentKey(alias: "book_name")
  String? name;

  // ignore the field in the document
  @IgnoredKey()
  String? author;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookId &&
          runtimeType == other.runtimeType &&
          isbn == other.isbn &&
          name == other.name &&
          author == other.author;

  @override
  int get hashCode => isbn.hashCode ^ name.hashCode ^ author.hashCode;

  @override
  String toString() {
    return 'BookId{isbn: $isbn, name: $name, author: $author}';
  }
}

// ==============================================================
// Data generator
// ==============================================================
var faker = Faker(seed: DateTime.now().millisecondsSinceEpoch);
var random = Random(DateTime.now().millisecondsSinceEpoch);
var tags = [
  'tag1',
  'tag2',
  'tag3',
  'tag4',
];
var publisher = [
  'publisher1',
  'publisher2',
  'publisher3',
  'publisher4',
];

Book randomBook() {
  var book = Book();
  book.bookId = randomBookId();
  book.tags = (tags.toList()..shuffle(random)).take(3).toList();
  book.description = faker.lorem.sentence();
  book.publisher = (publisher.toList()..shuffle(random)).first;
  book.price = random.nextDouble() * 1000;
  return book;
}

BookId randomBookId() {
  var bookId = BookId();
  bookId.isbn = faker.guid.guid();
  bookId.author = faker.person.name();
  bookId.name = faker.conference.name();
  return bookId;
}