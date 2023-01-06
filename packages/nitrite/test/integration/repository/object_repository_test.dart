import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  group('Object Repository Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();

      var mapper = db.config.nitriteMapper as SimpleDocumentMapper;
      mapper.registerEntityConverter(StressRecordConverter());
      mapper.registerEntityConverter(WithDateIdConverter());
      mapper.registerEntityConverter(WithTransientFieldConverter());
      mapper.registerEntityConverter(WithOutIdConverter());
      mapper.registerEntityConverter(ChildClassConverter());
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Without Id', () async {
      var repo = await db.getRepository<WithOutId>();
      var object = WithOutId(name: 'test', number: 2);

      await repo.insert([object]);
      var cursor = await repo.find();
      var instance = await cursor.first;
      expect(object, instance);
    });

    
  });
}
