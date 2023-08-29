import 'package:nitrite/nitrite.dart';

/// A class representing the result of a write operation in Nitrite database.
/// It is an iterable of [NitriteId]s of affected [Document]s.
class WriteResult extends Iterable<NitriteId> {
  final List<NitriteId> _nitriteIds;

  /// Creates a [WriteResult] with the given [nitriteIds].
  WriteResult(this._nitriteIds);

  /// Returns the number of [Document]s affected by the write operation.
  int getAffectedCount() {
    return _nitriteIds.length;
  }

  @override
  Iterator<NitriteId> get iterator => _nitriteIds.iterator;
}
