import 'package:nitrite/src/collection/find_plan.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/common/fields.dart';
import 'package:nitrite/src/index/fulltext/text_tokenizer.dart';
import 'package:nitrite/src/index/nitrite_index.dart';
import 'package:nitrite/src/index/types.dart';
import 'package:nitrite/src/store/nitrite_store.dart';

class TextIndex extends NitriteIndex {
  final IndexDescriptor _indexDescriptor;
  final NitriteStore _nitriteStore;
  final TextTokenizer _textTokenizer;

  TextIndex(this._textTokenizer, this._indexDescriptor, this._nitriteStore);

  @override
  Future<void> drop() {
    // TODO: implement drop
    throw UnimplementedError();
  }

  @override
  Stream<NitriteId> findNitriteIds(FindPlan findPlan) {
    // TODO: implement findNitriteIds
    throw UnimplementedError();
  }

  @override
  // TODO: implement indexDescriptor
  IndexDescriptor get indexDescriptor => throw UnimplementedError();

  @override
  Future<void> remove(FieldValues fieldValues) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<void> write(FieldValues fieldValues) {
    // TODO: implement write
    throw UnimplementedError();
  }


}
