import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// A [NitriteMapper] based on [EntityConverter] implementation.
class EntityConverterMapper extends NitriteMapper {
  final Set<String> _valueTypes = {};
  final Map<String, EntityConverter> _converterRegistry = {};

  /// Creates a new [EntityConverterMapper].
  EntityConverterMapper([List<Type> valueTypes = const []]) {
    _registerValueTypes(valueTypes);
  }

  @override
  dynamic tryConvert<Target, Source>(Source? source) {
    if (source == null) {
      return null;
    }

    if (_isValue(source)) {
      if (source is! Target) {
        return source;
      }

      return source as Target;
    } else if (_isValueType<Target>()) {
      return defaultValue<Target>();
    } else {
      if (Target == Document || isSubtype<Target, Document>()) {
        if (source is Document) {
          return source as Target;
        } else {
          return _convertToDocument<Source>(source) as Target;
        }
      } else if (source is Document) {
        return _convertFromDocument<Target, Source>(source);
      }
    }

    throw ObjectMappingException(
      'Cannot convert object of type ${source.runtimeType} '
      'to type $Target',
    );
  }

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {}

  /// Adds a value type to ignore during mapping.
  void addValueType<T>() {
    _valueTypes.add("$T");
    _valueTypes.add("$T?");
  }

  /// Registers an [EntityConverter].
  void registerEntityConverter(EntityConverter<dynamic> entityConverter) {
    entityConverter.notNullOrEmpty("entityConverter cannot be null");
    _converterRegistry["${entityConverter.entityType}"] = entityConverter;
    _converterRegistry["${entityConverter.entityType}?"] = entityConverter;
  }

  _registerValueTypes(List<Type> valueTypes) {
    _valueTypes.addAll(builtInTypes().map((e) => e.toString()));
    _valueTypes.add("$Enum");
    _valueTypes.add("$NitriteId");
    _valueTypes.addAll(valueTypes.map((e) => e.toString()));
  }

  bool _isValue(value) {
    return _valueTypes.any((type) => value.runtimeType.toString() == type);
  }

  bool _isValueType<T>() {
    return _valueTypes.contains('$T');
  }

  /// Converts an object of type [Source] to a document.
  Document _convertToDocument<Source>(Source source) {
    var type = source != null ? source.runtimeType.toString() : "$Source";
    if (_converterRegistry.containsKey(type)) {
      var serializer = _converterRegistry[type] as EntityConverter<Source>;
      try {
        return serializer.toDocument(source, this);
      } on StackOverflowError {
        throw ObjectMappingException('Circular reference detected in $type');
      }
    }

    throw ObjectMappingException('Can\'t convert object of type '
        '$type to Document, try registering a '
        'EntityConverter for it.');
  }

  /// Converts a document to a target object of type [Target].
  Target? _convertFromDocument<Target, Source>(Document source) {
    var type = "$Target";
    if (_converterRegistry.containsKey(type)) {
      var serializer = _converterRegistry[type] as EntityConverter<Target>;
      return serializer.fromDocument(source, this);
    }

    throw ObjectMappingException('Can\'t convert Document to type '
        '$type, try registering a EntityConverter for it.');
  }
}