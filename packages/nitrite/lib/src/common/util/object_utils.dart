import 'package:nitrite/nitrite.dart';

void blackHole(dynamic _) {}

bool isSubtype<S, T>() => <S>[] is List<T>;

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
