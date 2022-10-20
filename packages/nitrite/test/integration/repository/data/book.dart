import 'package:nitrite/nitrite.dart';

part 'book.no2.dart';

@Entity(name: 'books', indices: [
  Index(fields: ['tags'], type: IndexType.nonUnique),
  Index(fields: ['description'], type: IndexType.fullText),
  Index(fields: ['price', 'publisher']),
])
class Book with _$BookEntityMixin {
  @Id(fieldName: 'book_id', embeddedFields: ['isbn', 'book_name'])
  BookId? bookId;

  String? publisher;

  double? price;

  List<String> tags = [];

  String? description;

  Book(
      [this.bookId,
      this.publisher,
      this.price,
      this.tags = const [],
      this.description]);
}

class BookConverter extends EntityConverter<Book> {
  @override
  Book fromDocument(Document document, NitriteMapper nitriteMapper) {
    var book = Book();
    book.bookId =
        nitriteMapper.convert<BookId?, Document>(document['book_id']);
    book.publisher = document['publisher'];
    book.price = document['price'];
    book.tags = document['tags'];
    book.description = document['description'];
    return book;
  }

  @override
  Document toDocument(Book entity, NitriteMapper nitriteMapper) {
    return createDocument(
        'book_id', nitriteMapper.convert<Document, BookId>(entity.bookId))
      ..put('publisher', entity.publisher)
      ..put('price', entity.price)
      ..put('tags', entity.tags)
      ..put('description', entity.description);
  }
}

class BookId {
  String? isbn;
  String? name;
  String? author;
}

class BookIdConverter extends EntityConverter<BookId> {
  @override
  BookId fromDocument(Document document, NitriteMapper nitriteMapper) {
    var bookId = BookId();
    bookId.isbn = document['isbn'];
    bookId.name = document['book_name'];
    bookId.author = document['author'];
    return bookId;
  }

  @override
  Document toDocument(BookId entity, NitriteMapper nitriteMapper) {
    return createDocument('isbn', entity.isbn)
      ..put('book_name', entity.name)
      ..put('author', entity.author);
  }
}
