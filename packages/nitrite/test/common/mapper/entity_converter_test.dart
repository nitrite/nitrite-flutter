import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

part 'entity_converter_test.no2.dart';

void main() {
  group("EntityConverter Test Suite", () {
    test("Test FromList", () {
      var nitriteMapper = SimpleDocumentMapper();
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

      var doc = nitriteMapper.convert<Document, _A>(a);
      print(doc);
    });
  });
}

@Converter()
class _A {
  List<_B>? l;
  Set<_C>? s;
  Map<_K, _V?>? m;
  Map<String, _V>? ms;
  List<String> ls = [];

  _A({this.l, this.s, this.m, this.ms, this.ls = const []});
}

@Converter()
class _B {
  String? s;

  _B({this.s});
}

@Converter()
class _C {
  int? i;

  _C({this.i});
}

@Converter()
class _K {
  double? d;

  _K({this.d});
}

@Converter()
class _V {
  String? s;

  _V({this.s});
}
