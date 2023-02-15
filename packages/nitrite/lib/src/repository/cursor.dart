import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stream/mutated_object_stream.dart';
import 'package:nitrite/src/common/util/document_utils.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// An interface to iterate over [ObjectRepository.find] results.
///
/// ```dart
/// // create/open a database
/// var db = Nitrite().builder()
///   .openOrCreate("user", "password");
///
/// // create a repository
/// var repository = db.getRepository<Employee>();
///
/// // returns all ids un-filtered
/// var cursor = repository.find();
///
/// await for (var item in cursor) {
///   // use your logic with the retrieved object here
///   print(item);
/// }
/// ```
abstract class Cursor<T> extends StreamView<T> {
  Cursor(super.stream);

  /// Gets a filter plan for the query.
  FindPlan get findPlan;

  /// Projects the result of one type into an [Stream] of another type.
  Stream<Projection> project<Projection>();

  /// Performs a left outer join with a foreign cursor with the specified
  /// lookup parameters.
  ///
  /// It performs an equality match on the localField to the foreignField
  /// from the objects of the foreign cursor. If an input object does not
  /// contain the localField, the join treats the field as having a value
  /// of default value for matching purposes.
  Stream<Joined> leftJoin<Foreign, Joined>(
      Cursor<Foreign> foreignCursor, LookUp lookup);
}

class ObjectCursor<T> extends Cursor<T> {
  final DocumentCursor _documentCursor;
  final NitriteMapper _nitriteMapper;

  ObjectCursor(this._documentCursor, this._nitriteMapper)
      : super(MutatedObjectStream(_documentCursor, _nitriteMapper, false));

  @override
  FindPlan get findPlan => _documentCursor.findPlan;

  @override
  Stream<Projection> project<Projection>() {
    var dummyDoc = _emptyDocument<Projection>(_nitriteMapper);
    var projectedStream = _documentCursor.project(dummyDoc);
    return MutatedObjectStream(projectedStream, _nitriteMapper);
  }

  @override
  Stream<Joined> leftJoin<Foreign, Joined>(
      Cursor<Foreign> foreignCursor, LookUp lookup) {
    var foreignObjectCursor = foreignCursor as ObjectCursor<Foreign>;
    var joinedStream =
        _documentCursor.leftJoin(foreignObjectCursor._documentCursor, lookup);
    return MutatedObjectStream(joinedStream, _nitriteMapper);
  }

  Document _emptyDocument<D>(NitriteMapper nitriteMapper) {
    if (isSubtype<D, num>()) {
      throw ValidationException('Cannot project to a number type');
    } else if (isSubtype<D, Iterable>()) {
      throw ValidationException('Cannot project to an iterable type');
    }

    validateProjectionType<D>(nitriteMapper);

    var dummyDoc = skeletonDocument<D>(nitriteMapper);
    if (dummyDoc.isEmpty) {
      throw ValidationException("Cannot project to empty type");
    }
    return dummyDoc;
  }
}
