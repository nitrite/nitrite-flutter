import 'package:string_splitter/string_splitter.dart';

List<String> tokenizeString(String text) {
  return StringSplitter.split(
    text,
    splitters: [
      ' ',
      '\t',
      '\r\n',
      '\n',
      '\f',
      '+',
      '"',
      '*',
      '%',
      '&',
      '/',
      '(',
      ')',
      '=',
      '?',
      '\'',
      '!',
      ',',
      '.',
      ';',
      ':',
      '-',
      '_',
      '#',
      '@',
      '|',
      '^',
      '~',
      '`',
      '{',
      '}',
      '[',
      ']',
      '<',
      '>',
      '\\'
    ],
    trimParts: true,
  );
}