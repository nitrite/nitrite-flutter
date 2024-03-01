import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  group(retry: 3, 'Compound Index Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Find by Id', () async {
      var bookId = BookId();
      bookId.author = 'John Doe';
      bookId.isbn = '123456';
      bookId.name = 'Nitrite Database';

      var book = Book();
      book.bookId = bookId;
      book.description = 'Some random book description';
      book.price = 22.56;
      book.publisher = 'My Publisher House';
      book.tags = ['database', 'nosql'];

      await bookRepository.insert(book);

      var bookById = await bookRepository.getById(bookId);
      expect(bookById?.bookId, isNotNull);
      expect(bookById?.bookId?.author, isNull);

      // author is ignored for test, so setting back the author manually
      bookById?.bookId?.author = 'John Doe';
      expect(bookById, book);
    });

    test('Test Duplicate Index on Same Field', () async {
      expect(
          () async => await db.getRepository<WrongIndexEntity>(),
          throwsA(predicate((e) =>
              e is IndexingException &&
              e.message.contains('Index already exists on fields: '
                  '[name] with type Fulltext'))));
    });
  });
}
