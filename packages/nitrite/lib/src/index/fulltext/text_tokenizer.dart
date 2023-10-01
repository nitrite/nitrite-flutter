import 'package:nitrite/src/common/util/string_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/index/fulltext/languages.dart';
import 'package:nitrite/src/index/fulltext/stop_words.dart';

/// An abstract class representing a stop-word based text tokenizer.
abstract class TextTokenizer {
  /// Gets the language for the tokenizer.
  Languages get language;

  /// Tokenize a [text] and discards all stop-words from it.
  Set<String> tokenize(String text);

  /// Gets all stop-words for a language.
  Set<String> stopWords();
}

/// An abstract text tokenizer which tokenizes a given string.
/// It discards certain words known as stop word depending on
/// the language chosen.
abstract class BaseTextTokenizer implements TextTokenizer {
  @override
  Set<String> tokenize(String text) {
    var words = <String>{};
    if (text.isNullOrEmpty) return words;

    var tokens = tokenizeString(text);
    for (var token in tokens) {
      var word = convertWord(token);
      if (!word.isNullOrEmpty) {
        words.add(word!);
      }
    }

    return words;
  }

  /// Converts a `word` into all lower case and checks if it
  /// is a known stop word. If it is, then the `word` will be
  /// discarded and will not be considered as a valid token.
  String? convertWord(String word) {
    var convertedWord = word.toLowerCase();
    if (stopWords().contains(convertedWord)) {
      return null;
    }
    return convertedWord;
  }
}

/// A [TextTokenizer] implementation for the English languages.
class EnglishTextTokenizer extends BaseTextTokenizer {
  final Language _language = English();

  @override
  Languages get language => Languages.english;

  @override
  Set<String> stopWords() => _language.stopWords();
}

/// A [TextTokenizer] implementation that tokenizes text using a
/// universal approach.
class UniversalTextTokenizer extends BaseTextTokenizer {
  final Set<String> _stopWords = <String>{};

  UniversalTextTokenizer([List<Languages> languages = const []]) {
    if (languages.isEmpty || languages.contains(Languages.all)) {
      _loadAllLanguages();
    } else {
      _loadLanguage(languages);
    }
  }

  @override
  Languages get language => Languages.all;

  @override
  Set<String> stopWords() {
    return _stopWords;
  }

  void _loadAllLanguages() {
    _loadLanguage(Languages.values);
  }

  void _loadLanguage(List<Languages> languages) {
    for (var language in languages) {
      switch (language) {
        case Languages.afrikaans:
          _registerLanguage(Afrikaans());
          break;
        case Languages.arabic:
          _registerLanguage(Arabic());
          break;
        case Languages.armenian:
          _registerLanguage(Armenian());
          break;
        case Languages.basque:
          _registerLanguage(Basque());
          break;
        case Languages.bengali:
          _registerLanguage(Bengali());
          break;
        case Languages.brazilianPortuguese:
          _registerLanguage(BrazilianPortuguese());
          break;
        case Languages.breton:
          _registerLanguage(Breton());
          break;
        case Languages.bulgarian:
          _registerLanguage(Bulgarian());
          break;
        case Languages.catalan:
          _registerLanguage(Catalan());
          break;
        case Languages.chinese:
          _registerLanguage(Chinese());
          break;
        case Languages.croatian:
          _registerLanguage(Croatian());
          break;
        case Languages.czech:
          _registerLanguage(Czech());
          break;
        case Languages.danish:
          _registerLanguage(Danish());
          break;
        case Languages.dutch:
          _registerLanguage(Dutch());
          break;
        case Languages.english:
          _registerLanguage(English());
          break;
        case Languages.esperanto:
          _registerLanguage(Esperanto());
          break;
        case Languages.estonian:
          _registerLanguage(Estonian());
          break;
        case Languages.finnish:
          _registerLanguage(Finnish());
          break;
        case Languages.french:
          _registerLanguage(French());
          break;
        case Languages.galician:
          _registerLanguage(Galician());
          break;
        case Languages.german:
          _registerLanguage(German());
          break;
        case Languages.greek:
          _registerLanguage(Greek());
          break;
        case Languages.hausa:
          _registerLanguage(Hausa());
          break;
        case Languages.hebrew:
          _registerLanguage(Hebrew());
          break;
        case Languages.hindi:
          _registerLanguage(Hindi());
          break;
        case Languages.hungarian:
          _registerLanguage(Hungarian());
          break;
        case Languages.indonesian:
          _registerLanguage(Indonesian());
          break;
        case Languages.irish:
          _registerLanguage(Irish());
          break;
        case Languages.italian:
          _registerLanguage(Italian());
          break;
        case Languages.japanese:
          _registerLanguage(Japanese());
          break;
        case Languages.korean:
          _registerLanguage(Korean());
          break;
        case Languages.kurdish:
          _registerLanguage(Kurdish());
          break;
        case Languages.latin:
          _registerLanguage(Latin());
          break;
        case Languages.latvian:
          _registerLanguage(Latvian());
          break;
        case Languages.lithuanian:
          _registerLanguage(Lithuanian());
          break;
        case Languages.malay:
          _registerLanguage(Malay());
          break;
        case Languages.marathi:
          _registerLanguage(Marathi());
          break;
        case Languages.norwegian:
          _registerLanguage(Norwegian());
          break;
        case Languages.persian:
          _registerLanguage(Persian());
          break;
        case Languages.polish:
          _registerLanguage(Polish());
          break;
        case Languages.portuguese:
          _registerLanguage(Portuguese());
          break;
        case Languages.romanian:
          _registerLanguage(Romanian());
          break;
        case Languages.russian:
          _registerLanguage(Russian());
          break;
        case Languages.sesotho:
          _registerLanguage(Sesotho());
          break;
        case Languages.slovak:
          _registerLanguage(Slovak());
          break;
        case Languages.slovenian:
          _registerLanguage(Slovenian());
          break;
        case Languages.somali:
          _registerLanguage(Somali());
          break;
        case Languages.spanish:
          _registerLanguage(Spanish());
          break;
        case Languages.swahili:
          _registerLanguage(Swahili());
          break;
        case Languages.swedish:
          _registerLanguage(Swedish());
          break;
        case Languages.tagalog:
          _registerLanguage(Tagalog());
          break;
        case Languages.thai:
          _registerLanguage(Thai());
          break;
        case Languages.turkish:
          _registerLanguage(Turkish());
          break;
        case Languages.ukrainian:
          _registerLanguage(Ukrainian());
          break;
        case Languages.urdu:
          _registerLanguage(Urdu());
          break;
        case Languages.vietnamese:
          _registerLanguage(Vietnamese());
          break;
        case Languages.yoruba:
          _registerLanguage(Yoruba());
          break;
        case Languages.zulu:
          _registerLanguage(Zulu());
          break;
        case Languages.all:
          break;
      }
    }
  }

  void _registerLanguage(Language language) {
    _stopWords.addAll(language.stopWords());
  }
}
