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
      class Book {
        @Id(fieldName: 'book_id', embeddedFields: ['isbn', 'book_name'])
        BookId? bookId;
      
        String? publisher;
      
        double? price;
      
        List<String> tags = [];
      
        String? description;
      
        Book([this.bookId, this.publisher, this.price, this.tags = const [], this.description]);
      }
      
      class BookId {
        String? isbn;
        String? name;
        String? author;
      }
    ''');

    final actual = EntityWriter(entityInfo).write();

    expect(actual, equalsDart(r'''
      mixin _$BookEntityMixin implements NitriteEntity {@override
        String get entityName => "books";
        
        @override
        List<EntityIndex> get entityIndexes => const [
              EntityIndex(["tags"], IndexType.nonUnique),
              EntityIndex(["description"], IndexType.fullText),
              EntityIndex(["price", "publisher"], IndexType.unique),
            ] ;
            
        @override
        EntityId get entityId => EntityId(
              "book_id",
              false,
              ["isbn", "book_name"],
            ) ;
      }
    '''));
  });
}
