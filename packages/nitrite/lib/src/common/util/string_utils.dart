var _splitters = [
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
];

List<String> tokenizeString(String text) => _splitters.isEmpty
    ? [text]
    : text
        .split(RegExp(_splitters.map(RegExp.escape).join('|')))
        .where((element) => element.isNotEmpty)
        .toList();
