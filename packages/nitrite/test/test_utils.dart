import 'package:nitrite/nitrite.dart';
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
