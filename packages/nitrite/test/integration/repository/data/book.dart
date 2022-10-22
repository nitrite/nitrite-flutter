import 'package:nitrite/nitrite.dart';

part 'book.no2.dart';

@Converter(className: 'MyBookConverter')
@Entity(name: 'books', indices: [
  Index(fields: ['tags'], type: IndexType.nonUnique),
  Index(fields: ['description'], type: IndexType.fullText),
  Index(fields: ['price', 'publisher']),
])
class Book with _$BookEntityMixin {
  @Id(fieldName: 'book_id', embeddedFields: ['isbn', 'book_name'])
  @Property(alias: 'book_id')
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

@Converter()
class BookId {
  String? isbn;

  @Property(alias: "book_name")
  String? name;

  @IgnoredProperty()
  String? author;
}
