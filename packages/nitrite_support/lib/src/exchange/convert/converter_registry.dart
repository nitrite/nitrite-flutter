import 'package:nitrite_support/src/exchange/convert/builtin_converters.dart';
import 'package:nitrite_support/src/exchange/convert/converter.dart';

/// @nodoc
class ConverterRegistry {
  static final Map<int, Converter> _converters = {};

  ConverterRegistry() {
    registerBuiltInConverters();
  }

  void register(Converter converter) {
    if (_converters.containsKey(converter.typeId)) {
      throw ArgumentError(
          'Converter for type ${converter.typeId} already registered.');
    }
    _converters[converter.typeId] = converter;
  }

  Converter? getConverter(int typeId) {
    return _converters[typeId];
  }

  Converter? getConverterByValue(dynamic value) {
    Converter? match;
    for (var converter in _converters.values) {
      if (converter.matchesRuntimeType(value)) {
        return converter;
      }

      if (converter.matchesType(value) && match == null) {
        match = converter;
      }
    }
    return match;
  }

  void registerBuiltInConverters() {
    register(DateTimeConverter());
    register(NitriteIdConverter());
    register(DocumentConverter());
  }
}
