import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/index/nitrite_text_indexer.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  group(retry: 3, 'Universal Text Tokenizer Test', () {
    late ObjectRepository<TextData> textRepository;

    setUp(() async {
      setUpLog();

      var tokenizer = UniversalTextTokenizer(
          [Languages.bengali, Languages.chinese, Languages.english]);

      db = await Nitrite.builder()
          .fieldSeparator(".")
          .loadModule(module([NitriteTextIndexer(tokenizer)]))
          .openOrCreate();

      var documentMapper = db.config.nitriteMapper as EntityConverterMapper;
      documentMapper.registerEntityConverter(TextDataConverter());
      textRepository = await db.getRepository<TextData>();

      for (var i = 0; i < 10; i++) {
        var data = TextData();
        data.id = i;

        if (i % 2 == 0) {
          data.text = "তারা বলল, “এস আমরা আমাদের জন্যে এক বড় শহর বানাই| "
              "আর এমন একটি উঁচু স্তম্ভ বানাই যা আকাশ স্পর্শ করবে| তাহলে আমরা "
              "বিখ্যাত হব এবং এটা আমাদের এক সঙ্গে ধরে রাখবে| সারা পৃথিবীতে "
              "আমরা ছড়িয়ে থাকব না|”";
        } else if (i % 3 == 0) {
          data.text = "部汁楽示時葉没式将場参右属。覧観将者雄日語山銀玉襲政著約域費。"
              "新意虫跡更味株付安署審完顔団。困更表転定一史賀面政巣迎文学豊税乗。"
              "白間接特時京転閉務講封新内。側流効表害場測投活聞秀職探画労。"
              "福川順式極木注美込行警検直性禁遅。土一詳非物質紙姿漢人内池銀周街躍澹二。"
              "平討聞述並時全経詳業映回作朝送恵時。";
        } else if (i % 5 == 0) {
          data.text = " أقبل لسفن العالم، في أما, بـ بال"
              " أملاً الثالث،. الذود بالرّد الثالث، مع قام, كردة الضغوط الإمداد"
              " أن وصل. ٠٨٠٤ عُقر انتباه يكن قد, أن زهاء وفنلندا بال. لان ما"
              " يقوم المعاهدات, بـ بخطوط استعملت عدد. صفحة لفشل"
              " ولاتّساع لم قام, في مكثّفة الكونجرس جعل, الثالث، واتصار دون ان.\n";
        } else {
          data.text =
              "Lorem ipsum dolor sit amet, nobis audire perpetua eu sea. "
              "Te semper causae efficiantur per. Qui affert dolorum at. Mel "
              "tale constituto interesset in.";
        }

        await textRepository.insert(data);
      }
    });

    tearDown(() async {
      await textRepository.remove(all);

      await db.close();
    });

    test('Test Universal Full Text Indexing', () async {
      var cursor = textRepository.find(filter: where('text').text('Lorem'));
      expect(await cursor.length, 2);

      await for (var data in cursor) {
        if (data.id! % 2 == 0 || data.id! % 3 == 0 || data.id! % 5 == 0) {
          fail('Test failed');
        }
      }

      cursor = textRepository.find(filter: where('text').text('শহর'));
      expect(await cursor.length, 5);
      await for (var data in cursor) {
        if (data.id! % 2 != 0) {
          fail('Test failed');
        }
      }

      cursor = textRepository.find(filter: where('text').text('転閉'));
      expect(await cursor.length, 0);
      cursor = textRepository.find(filter: where('text').text('*転閉*'));
      expect(await cursor.length, 2);
      await for (var data in cursor) {
        if (data.id! % 3 != 0) {
          fail('Test failed');
        }
      }

      cursor = textRepository.find(filter: where('text').text("أقبل"));
      expect(await cursor.length, 1);
    });
  });
}
