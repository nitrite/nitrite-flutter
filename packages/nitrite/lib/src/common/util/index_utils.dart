import 'package:nitrite/nitrite.dart';

/// @nodoc
String deriveIndexMetaMapName(String collectionName) {
  return '$indexMetaPrefix$internalNameSeparator$collectionName';
}

/// @nodoc
String deriveIndexMapName(IndexDescriptor descriptor) {
  return indexPrefix +
      internalNameSeparator +
      descriptor.collectionName +
      internalNameSeparator +
      descriptor.fields.encodedName +
      internalNameSeparator +
      descriptor.indexType;
}
