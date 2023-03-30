import 'package:nitrite/nitrite.dart';

/// A class that implements this interface can be used to decorate
/// an entity of type T for nitrite database where using [Entity]
/// or its related annotations is not possible on a class.
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
          ? _entityDecorator.idField!.embeddedFieldNames
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
        await _collection.createIndex(
            fields, indexOptions(index.indexType));
      }
    }
  }
}
