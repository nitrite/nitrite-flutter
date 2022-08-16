import 'package:nitrite/nitrite.dart';

part 'book.no2.dart';

@Entity(name: 'books', indices: [
  Index(fields: ['tags'], type: IndexType.nonUnique),
  Index(fields: ['description'], type: IndexType.fullText),
  Index(fields: ['price', 'publisher']),
])
class Book with _$BookEntityMixin implements Mappable {
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

  @override
  void read(NitriteMapper? mapper, Document document) {
    bookId = mapper?.convert<BookId?, Document>(document['book_id']);
    publisher = document['publisher'];
    price = document['price'];
    tags = document['tags'];
    description = document['description'];
  }

  @override
  Document write(NitriteMapper? mapper) {
    return createDocument('book_id', mapper?.convert<Document, BookId>(bookId))
      ..put('publisher', publisher)
      ..put('price', price)
      ..put('tags', tags)
      ..put('description', description);
  }
}

class BookId implements Mappable {
  String? isbn;
  String? name;
  String? author;

  @override
  void read(NitriteMapper? mapper, Document document) {
    isbn = document['isbn'];
    name = document['book_name'];
    author = document['author'];
  }

  @override
  Document write(NitriteMapper? mapper) {
    return createDocument('isbn', isbn)
      ..put('book_name', name)
      ..put('author', author);
  }
}
