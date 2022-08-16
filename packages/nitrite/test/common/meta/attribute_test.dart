import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group('Attribute Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Attribute Test With Owner', () {
      var attrib = Attributes("name");
      expect(attrib[Attributes.owner], "name");
      expect(attrib[Attributes.createdTime], isNotNull);
      expect(attrib[Attributes.uniqueId], isNotNull);
    });

    test('Attribute Test Without Owner', () {
      var attrib = Attributes();
      expect(attrib[Attributes.owner], isNull);
      expect(attrib[Attributes.createdTime], isNotNull);
      expect(attrib[Attributes.uniqueId], isNotNull);
    });

    test('Attribute Test Set', () {
      var attrib = Attributes("name");
      attrib.set("key", "value");
      expect(attrib["key"], "value");
      expect(attrib["key2"], isNull);
    });
  });
}
