import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:test/test.dart';

Future<Nitrite> createDb([String? user, String? password]) => Nitrite.builder()
    .fieldSeparator(".")
    .openOrCreate(username: user, password: password);

const isNitriteException = TypeMatcher<NitriteException>();
const isIndexingException = TypeMatcher<IndexingException>();
const isInvalidIdException = TypeMatcher<InvalidIdException>();
const isInvalidOperationException = TypeMatcher<InvalidOperationException>();
const isNitriteIOException = TypeMatcher<NitriteIOException>();
const isValidationException = TypeMatcher<ValidationException>();
const isFilterException = TypeMatcher<FilterException>();
const isNotIdentifiableException = TypeMatcher<NotIdentifiableException>();
const isUniqueConstraintException = TypeMatcher<UniqueConstraintException>();
const isObjectMappingException = TypeMatcher<ObjectMappingException>();
const isPluginException = TypeMatcher<PluginException>();
const isNitriteSecurityException = TypeMatcher<NitriteSecurityException>();
const isMigrationException = TypeMatcher<MigrationException>();
const isTransactionException = TypeMatcher<TransactionException>();

final Matcher throwsNitriteException = throwsA(isNitriteException);
final Matcher throwsIndexingException = throwsA(isIndexingException);
final Matcher throwsInvalidIdException = throwsA(isInvalidIdException);
final Matcher throwsInvalidOperationException =
    throwsA(isInvalidOperationException);
final Matcher throwsNitriteIOException = throwsA(isNitriteIOException);
final Matcher throwsValidationException = throwsA(isValidationException);
final Matcher throwsFilterException = throwsA(isFilterException);
final Matcher throwsNotIdentifiableException =
    throwsA(isNotIdentifiableException);
final Matcher throwsUniqueConstraintException =
    throwsA(isUniqueConstraintException);
final Matcher throwsObjectMappingException = throwsA(isObjectMappingException);
final Matcher throwsPluginException = throwsA(isPluginException);
final Matcher throwsNitriteSecurityException =
    throwsA(isNitriteSecurityException);
final Matcher throwsMigrationException = throwsA(isMigrationException);
final Matcher throwsTransactionException = throwsA(isTransactionException);

bool isSorted<T extends Comparable<T>>(Iterable<T> iterable, bool ascending) {
  var iterator = iterable.iterator;
  if (!iterator.moveNext()) {
    return true;
  }

  var t = iterator.current;
  while (iterator.moveNext()) {
    var t2 = iterator.current;
    if (ascending) {
      if (t.compareTo(t2) > 0) {
        return false;
      }
    } else {
      if (t.compareTo(t2) < 0) {
        return false;
      }
    }
    t = t2;
  }

  return true;
}

bool isSimilarDocument(
    Document? document, Document? other, List<String> fields) {
  var result = true;
  if (document == null && other != null) return false;
  if (document != null && other == null) return false;
  if (document == null && other == null) return true;

  for (var field in fields) {
    result = result && deepEquals(document![field], other![field]);
  }
  return result;
}

class TestProcessor extends Processor {
  final Future<Document> Function(Document document) processAfterReadFn;
  final Future<Document> Function(Document document) processBeforeWriteFn;

  TestProcessor({
    required this.processAfterReadFn,
    required this.processBeforeWriteFn,
  });

  @override
  Future<Document> processAfterRead(Document document) {
    return processAfterReadFn(document);
  }

  @override
  Future<Document> processBeforeWrite(Document document) {
    return processBeforeWriteFn(document);
  }
}
