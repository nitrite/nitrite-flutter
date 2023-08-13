import 'package:nitrite/src/common/util/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group(retry: 3, "StringUtils Test Suite", () {
    test("Test TokenizeString", () {
      var string = '''
        A %quick\\;
        brown? >- f0x*jump{over}=th3 ^^lazy!
        dog.&cat
        ''';

      expect(tokenizeString(string).length, 10);
      expect(tokenizeString(string), [
        'A',
        'quick',
        'brown',
        'f0x',
        'jump',
        'over',
        'th3',
        'lazy',
        'dog',
        'cat'
      ]);
    });
  });
}
