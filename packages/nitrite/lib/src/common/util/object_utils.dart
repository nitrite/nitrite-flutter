import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';

abstract class ObjectUtils {
  
  static String getKeyName(String collectionName) {
     if (collectionName.contains(Constants.keyObjSeparator)){
       var split = collectionName.split(Constants.keyObjSeparator);
        return split[1];
     }
     throw ValidationException("$collectionName is not a valid keyed "
         "object repository");
  }

  static String getKeyedRepositoryType(String collectionName) {
    if (collectionName.contains(Constants.keyObjSeparator)){
      var split = collectionName.split(Constants.keyObjSeparator);
      return split[0];
    }
    throw ValidationException("$collectionName is not a valid keyed "
        "object repository");
  }
}
