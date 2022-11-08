import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  late Document doc;

  group('Document Test Suite', () {
    setUp(() {
      // Additional setup goes here.
      NitriteConfig().setFieldSeparator(".");

      doc = emptyDocument()
        ..put("score", 1034)
        ..put(
            "location",
            emptyDocument()
              ..put("state", "NY")
              ..put("city", "New York")
              ..put(
                  "address",
                  emptyDocument()
                    ..put("line1", "40")
                    ..put("line2", "ABC Street")
                    ..put("house", ["1", "2", "3"])))
        ..put("category", ['food', 'produce', 'grocery'])
        ..put("objArray",
            [createDocument("value", 1), createDocument("value", 2)]);
    });

    tearDown(() => NitriteConfig().setFieldSeparator("."));

    test('Create Document', () {
      expect(emptyDocument().isEmpty, isTrue);
      expect(createDocument("key", "value").size, 1);
      expect(documentFromMap(<String, dynamic>{}).size, 0);
    });

    test('Get Value', () {
      expect(doc[""], null);
      expect(doc["score"], 1034);
      expect(doc["location.state"], "NY");
      expect(
          doc["location.address"],
          emptyDocument()
            ..put("line1", "40")
            ..put("line2", "ABC Street")
            ..put("house", ["1", "2", "3"]));
      expect(doc["location.address.line1"], "40");
      expect(doc["location.address.line2"], "ABC Street");
      expect(doc["location.address.house"], ["1", "2", "3"]);
      expect(doc["location.address.house.0"], "1");
      expect(doc["location.address.house.1"], "2");
      expect(doc["location.address.house.2"], "3");
      expect(() => doc["location.address.house.3"], throwsValidationException);
      expect(doc["location.category"], null);

      expect(doc["category"], ['food', 'produce', 'grocery']);
      expect(doc["category.0"], 'food');
      expect(doc["category.1"], 'produce');
      expect(doc["category.2"], 'grocery');

      expect(doc["objArray"],
          [createDocument("value", 1), createDocument("value", 2)]);
      expect(doc["objArray.0"], createDocument("value", 1));
      expect(doc["objArray.1"], createDocument("value", 2));
      expect(doc["objArray.0.value"], 1);
      expect(doc["objArray.1.value"], 2);

      expect(
          doc["location.address.test"],
          isNot(emptyDocument()
            ..put("line1", "40")
            ..put("line2", "ABC Street")));
      expect(doc["location.address.test"], isNot("a"));
      expect(doc["."], isNull);
      expect(doc[".."], isNull);
      expect(doc["score.test"], isNull);
    });

    test('Get Value with Custom Field Separator', () {
      NitriteConfig().setFieldSeparator(":");

      expect(doc[""], null);
      expect(doc["score"], 1034);
      expect(doc["location:state"], "NY");
      expect(
          doc["location:address"],
          emptyDocument()
            ..put("line1", "40")
            ..put("line2", "ABC Street")
            ..put("house", ["1", "2", "3"]));
      expect(doc["location:address:line1"], "40");
      expect(doc["location:address:line2"], "ABC Street");
      expect(doc["location:address:house"], ["1", "2", "3"]);
      expect(doc["location:address:house:0"], "1");
      expect(doc["location:address:house:1"], "2");
      expect(doc["location:address:house:2"], "3");
      expect(() => doc["location:address:house:3"], throwsValidationException);
      expect(doc["location:category"], null);

      expect(doc["category"], ['food', 'produce', 'grocery']);
      expect(doc["category:0"], 'food');
      expect(doc["category:1"], 'produce');
      expect(doc["category:2"], 'grocery');

      expect(doc["objArray"],
          [createDocument("value", 1), createDocument("value", 2)]);
      expect(doc["objArray:0"], createDocument("value", 1));
      expect(doc["objArray:1"], createDocument("value", 2));
      expect(doc["objArray:0:value"], 1);
      expect(doc["objArray:1:value"], 2);

      expect(
          doc["location:address:test"],
          isNot(emptyDocument()
            ..put("line1", "40")
            ..put("line2", "ABC Street")));
      expect(doc["location:address:test"], isNot("a"));
      expect(doc[":"], isNull);
      expect(doc["::"], isNull);
      expect(doc["score:test"], isNull);

      expect(doc["location.address.line1"], isNull);
      expect(doc["location.address.line2"], isNull);
      expect(doc["location.address.house"], isNull);
      expect(doc["location:address:house.2"], isNull);
    });

    test("Test []= Operator", () {
      var document = emptyDocument();
      document['score'] = 1034;
      document['location'] = emptyDocument();
      document['location.state'] = 'NY';
      document['location.city'] = 'New York';
      document['location.address'] = emptyDocument();
      document['location.address.line1'] = '40';
      document['location.address.line2'] = 'ABC Street';
      document['location.address.house'] = ["1", "2", "3"];
      document['category'] = ['food', 'produce', 'grocery'];
      document['objArray'] = [
        createDocument("value", 1),
        createDocument("value", 2)
      ];

      expect(doc[""], null);
      expect(doc["score"], 1034);
      expect(doc["location.state"], "NY");
      expect(
          doc["location.address"],
          emptyDocument()
            ..put("line1", "40")
            ..put("line2", "ABC Street")
            ..put("house", ["1", "2", "3"]));
      expect(doc["location.address.line1"], "40");
      expect(doc["location.address.line2"], "ABC Street");
      expect(doc["location.address.house"], ["1", "2", "3"]);
      expect(doc["location.address.house.0"], "1");
      expect(doc["location.address.house.1"], "2");
      expect(doc["location.address.house.2"], "3");
      expect(() => doc["location.address.house.3"], throwsValidationException);
      expect(doc["location.category"], null);

      expect(doc["category"], ['food', 'produce', 'grocery']);
      expect(doc["category.0"], 'food');
      expect(doc["category.1"], 'produce');
      expect(doc["category.2"], 'grocery');

      expect(doc["objArray"],
          [createDocument("value", 1), createDocument("value", 2)]);
      expect(doc["objArray.0"], createDocument("value", 1));
      expect(doc["objArray.1"], createDocument("value", 2));
      expect(doc["objArray.0.value"], 1);
      expect(doc["objArray.1.value"], 2);

      expect(
          doc["location.address.test"],
          isNot(emptyDocument()
            ..put("line1", "40")
            ..put("line2", "ABC Street")));
      expect(doc["location.address.test"], isNot("a"));
      expect(doc["."], isNull);
      expect(doc[".."], isNull);
      expect(doc["score.test"], isNull);
    });

    test("Put NULL", () {
      var doc2 = doc.put("test", null);
      expect(doc2, isNotNull);
      expect(doc2["test"], null);
    });

    test("Put _id", () {
      expect(() => doc.put(docId, "value"), throwsInvalidIdException);
    });

    test("Get Invalid _id", () {
      var map = <String, dynamic>{};
      map[docId] = "value";
      expect(() => documentFromMap(map), throwsInvalidIdException);
    });

    test("Invalid Get", () {
      var key = "first.array.-1";
      var doc2 = createDocument("first", createDocument("array", []));
      expect(() => doc2[key], throwsValidationException);
    });

    test("Remove", () {
      expect(doc.size, 4);
      doc.remove("score");
      expect(doc.size, 3);
    });

    test("Remove with Custom Field Separator", () {
      NitriteConfig().setFieldSeparator(":");
      expect(doc["location:address"].size, 3);
      doc.remove("location:address:line1");
      expect(doc["location:address"].size, 2);
    });

    test("Remove with Custom Field Separator and Array", () {
      NitriteConfig().setFieldSeparator(":");
      expect(doc["location:address:house"].length, 3);
      doc.remove("location:address:house:0");
      expect(doc["location:address:house"].length, 2);

      expect(doc["objArray"].length, 2);
      doc.remove("objArray:0:value");
      expect(doc["objArray"].length, 2);
      expect(doc["objArray:0"].size, 0);
    });

    test("Get Fields", () {
      var fields = doc.fields;
      expect(fields.length, 5);
      expect(fields.contains("score"), true);
      expect(fields.contains("location.city"), true);
      expect(fields.contains("location.state"), true);
      expect(fields.contains("location.address.line1"), true);
      expect(fields.contains("location.address.line2"), true);
    });

    test("Get Embedded Array Fields", () {
      var document = createDocument("first", "value")
        ..put("second", ['1', '2'])
        ..put("third", null)
        ..put(
            "fourth",
            createDocument("first", "value")
              ..put("second", ['1', '2'])
              ..put("third",
                  createDocument("first", [1, 2])..put("second", "other")))
        ..put("fifth", [
          createDocument("first", "value")
            ..put("second", [1, 2, 3])
            ..put("third",
                createDocument("first", "value")..put("second", [1, 2]))
            ..put("fourth", <Document>[
              createDocument("first", "value")..put("second", [1, 2]),
              createDocument("first", "value")..put("second", [1, 2])
            ]),
          createDocument("first", "value")
            ..put("second", [3, 4, 5])
            ..put("third",
                createDocument("first", "value")..put("second", [1, 2]))
            ..put("fourth", <Document>[
              createDocument("first", "value")..put("second", [1, 2]),
              createDocument("first", "value")..put("second", [1, 2])
            ]),
          createDocument("first", "value")
            ..put("second", [5, 6, 7])
            ..put("third",
                createDocument("first", "value")..put("second", [1, 2]))
            ..put("fourth", <Document>[
              createDocument("first", "value")..put("second", [1, 2]),
              createDocument("first", "value")..put("second", [3, 4])
            ])
        ]);

      var list = document["fifth.second"]!;
      expect(list.length, 7);

      list = document["fifth.fourth.second"]!;
      expect(list.length, 4);

      var value = document["fourth.third.second"]!;
      expect(value, "other");

      var number = document["fifth.0.second.0"]!;
      expect(number, 1);

      number = document["fifth.1.fourth.0.second.1"]!;
      expect(number, 2);
    });

    test("Deep Put", () {
      doc.put("location.address.pin", 700037);
      expect(doc["location.address.pin"], 700037);

      doc.put("location.address.business.pin", 700037);
      expect(doc["location.address.business.pin"], 700037);
    });

    test("Deep Remove", () {
      doc.remove("location.address.line1");
      doc.remove("location.address.line2");
      doc.remove("location.address.house");
      expect(doc["location.address"], isNull);
    });
  });
}
