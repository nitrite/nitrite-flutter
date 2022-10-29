
import 'package:nitrite/nitrite.dart';

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
