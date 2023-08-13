import 'package:nitrite/nitrite.dart';

part 'example.no2.dart';

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
}
