import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// A [NitriteMapper] based on [EntityConverter] implementation.
///
/// This mapper is used by default in nitrite. It uses [EntityConverter]
/// to convert an object and vice versa.
class SimpleNitriteMapper extends NitriteMapper {
  final Set<String> _valueTypes = {};
  final Map<String, EntityConverter> _converterRegistry = {};

  /// Creates a new [SimpleNitriteMapper].
  SimpleNitriteMapper([List<Type> valueTypes = const []]) {
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
      } else if (source is Target || Target == dynamic) {
        return source;
      }
    }

    throw ObjectMappingException(
      'Cannot convert object of type ${source.runtimeType} '
      'to type $Target',
    );
  }

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {}

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
    var converter = _findEntityConverter(source);
    if (converter != null) {
      try {
        return converter.toDocument(source, this);
      } on StackOverflowError {
        throw ObjectMappingException('Circular reference detected in $source');
      }
    }

    throw ObjectMappingException('Can\'t convert object of type '
        '${source.runtimeType} to Document, try registering a '
        'EntityConverter for it.');
  }

  /// Converts a document to a target object of type [Target].
  Target? _convertFromDocument<Target, Source>(Document source) {
    var converter = _findEntityConverterByType<Target>();
    if (converter != null) {
      return converter.fromDocument(source, this) as Target;
    }

    throw ObjectMappingException('Can\'t convert Document to type '
        '$Target, try registering a EntityConverter for it.');
  }

  EntityConverter? _findEntityConverter(dynamic value) {
    EntityConverter? match;
    for (var converter in _converterRegistry.values) {
      if (converter.matchesRuntimeType(value)) {
        return converter;
      }

      if (converter.matchesType(value) && match == null) {
        match = converter;
      }
    }
    return match;
  }

  EntityConverter? _findEntityConverterByType<T>() {
    for (var converter in _converterRegistry.values) {
      if (converter.matchesByType<T>()) {
        return converter;
      }

      if (converter.matchesByType<T?>()) {
        return converter;
      }
    }
    return null;
  }
}
