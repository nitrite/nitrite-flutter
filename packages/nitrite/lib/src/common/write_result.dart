import 'package:nitrite/nitrite.dart';

class WriteResult extends Iterable<NitriteId> {
  final List<NitriteId> _nitriteIds;

  WriteResult(this._nitriteIds);

  int getAffectedCount() {
    return _nitriteIds.length;
  }

  @override
  Iterator<NitriteId> get iterator => _nitriteIds.iterator;
}
