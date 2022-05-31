import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';

String getKeyName(String collectionName) {
  if (collectionName.contains(Constants.keyObjSeparator)) {
    var split = collectionName.split(Constants.keyObjSeparator);
    return split[1];
  }
  throw ValidationException("$collectionName is not a valid keyed "
      "object repository");
}

String getKeyedRepositoryType(String collectionName) {
  if (collectionName.contains(Constants.keyObjSeparator)) {
    var split = collectionName.split(Constants.keyObjSeparator);
    return split[0];
  }
  throw ValidationException("$collectionName is not a valid keyed "
      "object repository");
}

bool deepEquals(fieldValue, value) {
  throw UnimplementedError();
}
