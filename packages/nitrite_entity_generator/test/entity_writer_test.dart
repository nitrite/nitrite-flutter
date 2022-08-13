import 'package:code_builder/code_builder.dart';
import 'package:nitrite_entity_generator/src/entity_writer.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test("Parse Id field", () async {
    final entityInfo = await createEntityInfo('''
      @Entity(name: 'books', indices: [
        Index(fields: ['tags'], type: IndexType.nonUnique),
        Index(fields: ['description'], type: IndexType.fullText),
        Index(fields: ['price', 'publisher']),
      ])
      class Book implements Mappable {
        @Id(fieldName: 'book_id', embeddedFields: ['isbn', 'book_name'])
        BookId? bookId;
      
        String? publisher;
      
        double? price;
      
        List<String> tags = [];
      
        String? description;
      
        Book([this.bookId, this.publisher, this.price, this.tags = const [], this.description]);
      
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
    ''');

    final actual = EntityWriter(entityInfo).write();

    expect(actual, equalsDart(r'''
      mixin _$BookEntityMixin implements NitriteEntity {@override
        String get entityName => "books";
        
        @override
        List<EntityIndex> get entityIndexes => [
              EntityIndex(["tags"], IndexType.nonUnique),
              EntityIndex(["description"], IndexType.fullText),
              EntityIndex(["price", "publisher"], IndexType.unique),
            ] ;
            
        @override
        EntityId get entityId => EntityId(
              "book_id",
              ["isbn", "book_name"],
            ) ;
      }
    '''));
  });
}