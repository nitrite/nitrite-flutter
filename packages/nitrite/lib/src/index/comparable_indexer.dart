import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/index/compound_index.dart';
import 'package:nitrite/src/index/single_field_index.dart';

/// @nodoc
abstract class ComparableIndexer extends NitriteIndexer {
  final Map<IndexDescriptor, NitriteIndex> _indexRegistry = {};

  bool get isUnique;

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {}

  @override
  Future<void> validateIndex(Fields fields) async {}

  @override
  Stream<NitriteId> findByFilter(
      FindPlan findPlan, NitriteConfig nitriteConfig) {
    var nitriteIndex =
        _findNitriteIndex(findPlan.indexDescriptor, nitriteConfig);
    return nitriteIndex.findNitriteIds(findPlan);
  }

  @override
  Future<void> writeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) async {
    var nitriteIndex = _findNitriteIndex(indexDescriptor, nitriteConfig);
    return nitriteIndex.write(fieldValues);
  }

  @override
  Future<void> removeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) async {
    var nitriteIndex = _findNitriteIndex(indexDescriptor, nitriteConfig);
    return nitriteIndex.remove(fieldValues);
  }

  @override
  Future<void> dropIndex(
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) async {
    var nitriteIndex = _findNitriteIndex(indexDescriptor, nitriteConfig);
    return nitriteIndex.drop();
  }

  NitriteIndex _findNitriteIndex(
      IndexDescriptor? indexDescriptor, NitriteConfig nitriteConfig) {
    if (indexDescriptor == null) {
      throw IndexingException('Index descriptor cannot be null');
    }

    if (_indexRegistry.containsKey(indexDescriptor)) {
      return _indexRegistry[indexDescriptor]!;
    }

    NitriteIndex nitriteIndex;
    if (indexDescriptor.isCompoundIndex) {
      nitriteIndex =
          CompoundIndex(indexDescriptor, nitriteConfig.getNitriteStore());
    } else {
      nitriteIndex =
          SingleFieldIndex(indexDescriptor, nitriteConfig.getNitriteStore());
    }

    _indexRegistry[indexDescriptor] = nitriteIndex;
    return nitriteIndex;
  }
}

/// @nodoc
class UniqueIndexer extends ComparableIndexer {
  @override
  String get indexType => IndexType.unique;

  @override
  bool get isUnique => true;
}

/// @nodoc
class NonUniqueIndexer extends ComparableIndexer {
  @override
  String get indexType => IndexType.nonUnique;

  @override
  bool get isUnique => false;
}
