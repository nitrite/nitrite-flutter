import 'package:dbinspect_bridge/dbinspect_bridge.dart';
import 'package:nitrite/nitrite.dart';

/// The v1 filter operators this implementation actually supports.
///
/// **`exists` was absent until nitrite-flutter 3.0.0 and is now here.** It is
/// listed in `docs/PROTOCOL.md` §4.1 and was reported unsupported for as long as
/// the fluent API had nothing that tested for a field's presence; 2.1.0 added
/// `where(f).exists()` and this adapter now maps onto it. `filterOps` stays
/// authoritative either way — that is the mechanism that let the gap be honest
/// rather than mistranslated, and it is what makes closing it a one-line change.
///
/// `between` and `elemMatch` are the other direction — Dart has them and v1
/// does not, so they stay out until the protocol gains them.
const nitriteFilterOps = [
  'eq',
  'ne',
  'gt',
  'gte',
  'lt',
  'lte',
  'in',
  'notIn',
  'exists',
  'text',
];

/// Reported in `filterOps` only when the developer set `allowRegex`
/// (threat model F10, criterion 9).
const nitriteRegexOp = 'regex';

/// Threat model F10 fix 3, and explicitly best-effort.
const maxRegexPatternLength = 256;

/// A filter tree arrives from a paired but untrusted client, and each level is
/// a stack frame. Deep enough nesting is a crash inside the developer's
/// application, which is the same class of problem as an unbounded frame.
const maxFilterDepth = 16;

/// Turns the wire filter tree into a Nitrite [Filter].
///
/// Every refusal is a [BridgeException] with `badRequest`, never a silently
/// dropped clause: returning an unfiltered page would show the developer rows
/// they explicitly excluded.
Filter parseFilter(Map<String, Object?> tree, {required bool allowRegex}) =>
    _parse(tree, allowRegex: allowRegex, depth: 0);

Filter _parse(Object? node, {required bool allowRegex, required int depth}) {
  if (depth > maxFilterDepth) {
    throw BridgeException(
        BridgeErrorKind.badRequest, 'filter is nested too deeply');
  }
  if (node is! Map<String, Object?>) {
    throw BridgeException(
        BridgeErrorKind.badRequest, 'a filter node must be an object');
  }

  final conjunction = node['and'];
  if (conjunction != null) {
    return _combine(conjunction, allowRegex, depth, and);
  }
  final disjunction = node['or'];
  if (disjunction != null) {
    return _combine(disjunction, allowRegex, depth, or);
  }
  final negation = node['not'];
  if (negation != null) {
    return _parse(negation, allowRegex: allowRegex, depth: depth + 1).not();
  }
  return _leaf(node, allowRegex: allowRegex);
}

Filter _combine(
  Object? raw,
  bool allowRegex,
  int depth,
  Filter Function(List<Filter>) join,
) {
  if (raw is! List || raw.isEmpty) {
    throw BridgeException(
        BridgeErrorKind.badRequest, 'and/or takes a non-empty list of filters');
  }
  final parts = [
    for (final child in raw)
      _parse(child, allowRegex: allowRegex, depth: depth + 1)
  ];
  // Nitrite's `and`/`or` throw below two operands, and the protocol's own
  // `queryPage` example sends a one-element `and`. One clause is itself.
  return parts.length == 1 ? parts.single : join(parts);
}

Filter _leaf(Map<String, Object?> node, {required bool allowRegex}) {
  final field = node['field'];
  final op = node['op'];
  if (field is! String || field.isEmpty) {
    throw BridgeException(
        BridgeErrorKind.badRequest, 'a filter needs a field name');
  }
  if (op is! String) {
    throw BridgeException(
        BridgeErrorKind.badRequest, 'a filter needs an operator');
  }

  final value = node['value'];
  final on = where(field);
  switch (op) {
    case 'eq':
      return on.eq(value);
    case 'ne':
      return on.notEq(value);
    case 'gt':
      return on.gt(_ordered(value, op));
    case 'gte':
      return on.gte(_ordered(value, op));
    case 'lt':
      return on.lt(_ordered(value, op));
    case 'lte':
      return on.lte(_ordered(value, op));
    case 'in':
      return on.within(_orderedList(value, op));
    case 'notIn':
      return on.notIn(_orderedList(value, op));
    case 'exists':
      // Presence only, and `value` is deliberately ignored: `exists: false` is
      // not "does not exist" in the protocol — that is `not`. Reading the value
      // would select the opposite rows for a client that sent one by habit.
      return on.exists();
    case 'text':
      return on.text(_text(value));
    case nitriteRegexOp:
      if (!allowRegex) {
        // F10's load-bearing mitigation: off unless the developer opted in,
        // and absent from `filterOps` when off.
        throw BridgeException(
            BridgeErrorKind.badRequest, 'regex is not enabled on this adapter');
      }
      return on.regex(_pattern(value));
    default:
      throw BridgeException(BridgeErrorKind.badRequest,
          'this adapter does not support the "$op" operator');
  }
}

/// Ordering comparisons need something the store can order. A bool or an object
/// would throw inside the engine mid-page; refusing here names the problem.
Comparable<Object?> _ordered(Object? value, String op) {
  if (value is num) return value as Comparable<Object?>;
  if (value is String) return value as Comparable<Object?>;
  throw BridgeException(BridgeErrorKind.badRequest,
      '"$op" needs a number or a string to compare against');
}

List<Comparable<Object?>> _orderedList(Object? value, String op) {
  if (value is! List || value.isEmpty) {
    throw BridgeException(
        BridgeErrorKind.badRequest, '"$op" needs a non-empty list of values');
  }
  return [for (final element in value) _ordered(element, op)];
}

String _text(Object? value) {
  if (value is! String || value.isEmpty) {
    throw BridgeException(
        BridgeErrorKind.badRequest, '"text" needs a string to search for');
  }
  return value;
}

/// A group that ends in a quantifier and is itself quantified — `(a+)+`,
/// `(?:a*)*`, `(a{1,3})+`. This is the shape behind exponential backtracking,
/// and it is the pattern criterion 9 names.
final _nestedQuantifier = RegExp(r'[*+}]\)[*+{]');

/// F10 fixes 3: a length cap and a best-effort nested-quantifier refusal.
///
/// **Best-effort is the honest word.** A Dart `RegExp` match cannot be
/// interrupted inside its isolate, so no deadline can rescue a pattern that has
/// already started backtracking — which is why `allowRegex` defaulting to off
/// is the mitigation that actually carries the weight, and this one is a second
/// line rather than the line.
String _pattern(Object? value) {
  if (value is! String || value.isEmpty) {
    throw BridgeException(
        BridgeErrorKind.badRequest, '"regex" needs a pattern');
  }
  if (value.length > maxRegexPatternLength) {
    throw BridgeException(BridgeErrorKind.badRequest,
        'regex patterns are limited to $maxRegexPatternLength characters');
  }
  if (_nestedQuantifier.hasMatch(value)) {
    throw BridgeException(
        BridgeErrorKind.badRequest,
        'this regex has a nested quantifier and is refused: it can take '
        'exponential time, and a Dart match cannot be interrupted once it has '
        'started');
  }
  try {
    RegExp(value);
  } on FormatException {
    throw BridgeException(
        BridgeErrorKind.badRequest, 'this regex is not a valid pattern');
  }
  return value;
}
