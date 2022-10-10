
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';

String deriveIndexMetaMapName(String collectionName) {
  return '$indexMetaPrefix$internalNameSeparator$collectionName';
}

String deriveIndexMapName(IndexDescriptor descriptor) {
  return indexPrefix +
      internalNameSeparator +
      descriptor.collectionName +
      internalNameSeparator +
      descriptor.fields.encodedName +
      internalNameSeparator +
      descriptor.indexType;
}
