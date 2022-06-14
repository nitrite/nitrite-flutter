import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/db_value.dart';
import 'package:nitrite/src/common/sort_order.dart';

class SortedDocumentStream extends StreamView<Document> {
  SortedDocumentStream(FindPlan findPlan, Stream<Document> rawStream)
      : super(_sort(findPlan, rawStream));

  static Stream<Document> _sort(
      FindPlan findPlan, Stream<Document> rawStream) async* {
    var list = await rawStream.toList();
    list.sort((a, b) => _compare(a, b, findPlan.blockingSortOrder));
    for (var doc in list) {
      yield doc;
    }
  }

  static _compare(
      Document a, Document b, List<Pair<String, SortOrder>> sortOrder) {
    if (sortOrder.isEmpty) {
      return 0;
    }

    for (var value in sortOrder) {
      var field = value.first;
      var order = value.second;

      var aValue = a[field];
      var bValue = b[field];

      // handle null values
      int result;
      if ((aValue == null || aValue is DBNull) && bValue != null) {
        result = -1;
      } else if (aValue != null && (bValue == null || bValue is DBNull)) {
        result = 1;
      } else if (aValue == null) {
        result = -1;
      } else {
        // validate comparable
        if (aValue is! Comparable || bValue is! Comparable) {
          throw ValidationException(
              "Cannot compare ${aValue.runtimeType} and ${bValue.runtimeType}");
        }

        // compare values
        result = aValue.compareTo(bValue);

        if (order == SortOrder.descending) {
          result = -result;
        }

        // if both values are equal, continue to next sort order
        if (result != 0) {
          return result;
        }
      }

      return result;
    }
  }
}
