import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';

void blackHole(dynamic _) {}

String getKeyName(String collectionName) {
  if (collectionName.contains(keyObjSeparator)) {
    var split = collectionName.split(keyObjSeparator);
    return split[1];
  }
  throw ValidationException("$collectionName is not a valid keyed "
      "object repository");
}

String getKeyedRepositoryType(String collectionName) {
  if (collectionName.contains(keyObjSeparator)) {
    var split = collectionName.split(keyObjSeparator);
    return split[0];
  }
  throw ValidationException("$collectionName is not a valid keyed "
      "object repository");
}

bool deepEquals(fieldValue, value) {
  throw UnimplementedError();
}

int compare(Comparable a, Comparable b) {
  throw UnimplementedError();
}
