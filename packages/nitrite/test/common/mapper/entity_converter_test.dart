import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

part 'entity_converter_test.no2.dart';

void main() {
  group(retry: 3, "EntityConverter Test Suite", () {
    test("Test Helper Methods", () {
      var nitriteMapper = SimpleNitriteMapper();
      nitriteMapper.registerEntityConverter(_AConverter());
      nitriteMapper.registerEntityConverter(_BConverter());
      nitriteMapper.registerEntityConverter(_CConverter());
      nitriteMapper.registerEntityConverter(_KConverter());
      nitriteMapper.registerEntityConverter(_VConverter());

      var ls = ["a", "b", "c", "d"];
      var ms = {"a": _V(s: "aa"), "b": _V(s: "bb"), "c": _V(s: "cc")};
      var m = {
        _K(d: 1.2): _V(s: "aaa"),
        _K(d: 2.5): _V(s: "bbb"),
        _K(d: 0.2): _V(s: "ccc")
      };
      var s = {_C(i: 1), _C(i: 2), _C(i: 3)};
      var l = [_B(s: "aaa"), _B(s: "bbb"), _B(s: "ccc")];
      var a = _A(l: l, s: s, m: m, ms: ms, ls: ls);

      var doc = nitriteMapper.tryConvert<Document, _A>(a);

      var a1 = nitriteMapper.tryConvert<_A, Document>(doc);
      expect(a1, a);
    });
  });
}

@GenerateConverter()
class _A {
  List<_B>? l;
  Set<_C>? s;
  Map<_K, _V?>? m;
  Map<String, _V>? ms;
  List<String> ls = [];

  _A({this.l, this.s, this.m, this.ms, this.ls = const []});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _A &&
          runtimeType == other.runtimeType &&
          ListEquality().equals(l, other.l) &&
          SetEquality().equals(s, other.s) &&
          MapEquality().equals(m, other.m) &&
          MapEquality().equals(ms, other.ms) &&
          ListEquality().equals(ls, other.ls);

  @override
  int get hashCode =>
      l.hashCode ^ s.hashCode ^ m.hashCode ^ ms.hashCode ^ ls.hashCode;
}

@GenerateConverter()
class _B {
  String? s;

  _B({this.s});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _B && runtimeType == other.runtimeType && s == other.s;

  @override
  int get hashCode => s.hashCode;
}

@GenerateConverter()
class _C {
  int? i;

  _C({this.i});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _C && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

@GenerateConverter()
class _K {
  double? d;

  _K({this.d});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _K && runtimeType == other.runtimeType && d == other.d;

  @override
  int get hashCode => d.hashCode;
}

@GenerateConverter()
class _V {
  String? s;

  _V({this.s});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _V && runtimeType == other.runtimeType && s == other.s;

  @override
  int get hashCode => s.hashCode;
}
