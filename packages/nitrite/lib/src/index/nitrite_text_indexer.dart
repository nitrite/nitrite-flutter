import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/index/text_index.dart';

/// @nodoc
class NitriteTextIndexer extends NitriteIndexer {
  final TextTokenizer _tokenizer;
  final Map<IndexDescriptor, TextIndex> _indexRegistry = {};

  NitriteTextIndexer([TextTokenizer? tokenizer])
      : _tokenizer = tokenizer ?? EnglishTextTokenizer();

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {}

  @override
  String get indexType => IndexType.fullText;

  @override
  Future<void> validateIndex(Fields fields) async {
    if (fields.fieldNames.length > 1) {
      throw IndexingException(
          'Text index can only be created on a single field');
    }
  }

  @override
  Future<void> dropIndex(
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var textIndex = _findTextIndex(indexDescriptor, nitriteConfig);
    return textIndex.drop();
  }

  @override
  Future<void> writeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var textIndex = _findTextIndex(indexDescriptor, nitriteConfig);
    return textIndex.write(fieldValues);
  }

  @override
  Future<void> removeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var textIndex = _findTextIndex(indexDescriptor, nitriteConfig);
    return textIndex.remove(fieldValues);
  }

  @override
  Stream<NitriteId> findByFilter(
      FindPlan findPlan, NitriteConfig nitriteConfig) {
    var textIndex = _findTextIndex(findPlan.indexDescriptor!, nitriteConfig);
    return textIndex.findNitriteIds(findPlan);
  }

  @override
  Future<void> close() async {
    _indexRegistry.clear();
  }

  TextIndex _findTextIndex(
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    if (_indexRegistry.containsKey(indexDescriptor)) {
      return _indexRegistry[indexDescriptor]!;
    }

    var textIndex =
        TextIndex(_tokenizer, indexDescriptor, nitriteConfig.getNitriteStore());
    _indexRegistry[indexDescriptor] = textIndex;
    return textIndex;
  }
}
