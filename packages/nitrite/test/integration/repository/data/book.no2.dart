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
