import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/index_utils.dart';
import 'package:test/test.dart';

void main() {
  group("IndexUtils Test Suite", () {
    test('Test DeriveIndexMetaMapName', () {
      expect(deriveIndexMetaMapName('collectionName'),
          '$indexMetaPrefix${internalNameSeparator}collectionName');
    });

    test('Test DeriveIndexMapName', () {
      expect(
          deriveIndexMapName(IndexDescriptor(
              IndexType.unique, Fields.withNames(['name']), 'collectionName')),
          '$indexPrefix${internalNameSeparator}collectionName'
          '${internalNameSeparator}name${internalNameSeparator}Unique');
    });

    test('Test DeriveIndexMapName with NonUnique Index', () {
      expect(
          deriveIndexMapName(IndexDescriptor(IndexType.nonUnique,
              Fields.withNames(['name', 'age']), 'collectionName')),
          '$indexPrefix${internalNameSeparator}collectionName'
          '${internalNameSeparator}name${internalNameSeparator}age'
          '${internalNameSeparator}NonUnique');
    });

    test('Test DeriveIndexMapName with FullText Index', () {
      expect(
          deriveIndexMapName(IndexDescriptor(IndexType.fullText,
              Fields.withNames(['name', 'age']), 'collectionName')),
          '$indexPrefix${internalNameSeparator}collectionName'
          '${internalNameSeparator}name${internalNameSeparator}age'
          '${internalNameSeparator}Fulltext');
    });
  });
}
