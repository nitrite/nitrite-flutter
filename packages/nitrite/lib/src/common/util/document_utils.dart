
import 'package:nitrite/nitrite.dart';

FieldValues getDocumentValues(Document document, Fields fields) {
  var fieldValues = FieldValues();
  fieldValues.nitriteId = document.id;
  fieldValues.fields = fields;

  for (var field in fields.fieldNames) {
    var value = document.get(field);
    fieldValues.values.add(Pair(field, value));
  }

  return fieldValues;
}
