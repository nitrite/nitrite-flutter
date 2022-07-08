
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

Document skeletonDocument<T>(NitriteMapper nitriteMapper) {
  if (nitriteMapper.isValueType<T>()) {
    return Document.emptyDocument();
  }

  var dummy = nitriteMapper.newInstance<T>();
  var document = nitriteMapper.convert<Document, T>(dummy);
  if (document != null) {
    return _removeValues(document);
  }

  return Document.emptyDocument();
}


Document _removeValues(Document document) {
  for (var entry in document) {
    if (entry.second is Document) {
      document.put(entry.first, _removeValues(entry.second as Document));
    } else {
      document.put(entry.first, null);
    }
  }
  return document;
}
