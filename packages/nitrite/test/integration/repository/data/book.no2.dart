// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// NitriteEntityGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_internal_member

mixin _$BookEntityMixin implements NitriteEntity {
  @override
  String get entityName => "books";
  @override
  List<EntityIndex> get entityIndexes => [
        EntityIndex(["tags"], IndexType.nonUnique),
        EntityIndex(["description"], IndexType.fullText),
        EntityIndex(["price", "publisher"], IndexType.unique),
      ];
  @override
  EntityId get entityId => EntityId(
        "book_id",
        ["isbn", "book_name"],
      );
}

// **************************************************************************
// ConverterGenerator
// **************************************************************************

class MyBookConverter extends EntityConverter<Book> {
  @override
  Book fromDocument(Document document, NitriteMapper nitriteMapper) {
    var entity = Book();
    entity.bookId =
        nitriteMapper.convert<BookId?, Document>(document['book_id']);
    entity.publisher = document['publisher'];
    entity.price = document['price'];
    entity.tags = EntityConverter.toList(document['tags'], nitriteMapper);
    entity.description = document['description'];
    return entity;
  }

  @override
  Document toDocument(Book entity, NitriteMapper nitriteMapper) {
    var document = emptyDocument();
    document.put(
        'book_id', nitriteMapper.convert<Document, BookId?>(entity.bookId));
    document.put('publisher', entity.publisher);
    document.put('price', entity.price);
    document.put('tags', EntityConverter.fromList(entity.tags, nitriteMapper));
    document.put('description', entity.description);
    return document;
  }
}

class BookIdConverter extends EntityConverter<BookId> {
  @override
  BookId fromDocument(Document document, NitriteMapper nitriteMapper) {
    var entity = BookId();
    entity.isbn = document['isbn'];
    entity.name = document['book_name'];
    return entity;
  }

  @override
  Document toDocument(BookId entity, NitriteMapper nitriteMapper) {
    var document = emptyDocument();
    document.put('isbn', entity.isbn);
    document.put('book_name', entity.name);
    return document;
  }
}
