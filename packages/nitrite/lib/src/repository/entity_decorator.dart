import 'package:nitrite/nitrite.dart';

/// An interface that can be used to implement a decorator
/// for an entity class of type [T], where annotating the class
/// with [Entity] or its friends is not possible.
abstract class EntityDecorator<T> {
  /// Gets the entity type of the decorator.
  Type get entityType => T;

  /// Gets id field declaration.
  EntityId? get idField;

  /// Gets index fields declaration.
  List<EntityIndex> get indexFields;

  /// Gets entity name.
  String get entityName => T.toString();
}

/// @nodoc
class EntityDecoratorReader<T> {
  final EntityDecorator<T> _entityDecorator;
  final NitriteCollection _collection;

  EntityId? _objectIdField;

  EntityDecoratorReader(this._entityDecorator, this._collection);

  EntityId? get objectIdField => _objectIdField;

  Future<void> readAndExecute() async {
    if (_entityDecorator.idField != null) {
      _objectIdField = _entityDecorator.idField;

      var idFieldNames = _entityDecorator.idField!.isEmbedded
          ? _entityDecorator.idField!.encodedFieldNames
          : [_entityDecorator.idField!.fieldName];

      var hasIndex = await _collection.hasIndex(idFieldNames);
      if (!hasIndex) {
        await _collection.createIndex(
            idFieldNames, indexOptions(IndexType.unique));
      }
    }

    var indexes = _entityDecorator.indexFields;
    for (var index in indexes) {
      var fields = index.fieldNames;
      var hasIndex = await _collection.hasIndex(fields);
      if (!hasIndex) {
        await _collection.createIndex(fields, indexOptions(index.indexType));
      }
    }
  }
}
