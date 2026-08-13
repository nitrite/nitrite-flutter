## 0.1.0

- First release. `NitriteAdapter` for `dbinspect_bridge`: collections and
  handed-in repositories as stores, schema inferred from a document sample and
  always flagged as inferred, paging over `FindOptions` skip/limit/orderBy, the
  JSON filter DSL, and watch over Nitrite's collection subscription.
- `capabilities.filterOps` reports `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `in`,
  `notIn`, `exists` and `text`. `exists` needs nitrite 3.0.0, which is why this
  package requires it: the operator was reported unsupported for as long as the
  fluent API had nothing that tested for a field's presence.
- `regex` is off unless `allowRegex` is set, and refused with a length cap and a
  nested-quantifier check when it is on. Dart's `RegExp` backtracks and a match
  cannot be interrupted, so the default is the mitigation that matters.
- Row editing behind `allowWrite`: `insertRow`, `updateRow` and `deleteRow`,
  addressed by `_id`. An update is partial, `changes: 0` means the row was not
  there, and `_id` inside an update's `values` is refused — Nitrite merges an
  update document, so it would rewrite the identity of the row it just matched.
- Every client-supplied store name is resolved against the set the adapter
  reported: `Nitrite.getCollection` creates a collection that does not exist,
  and a write goes through the same allow-list.
- Sorting by a field no sampled document carries is refused rather than
  silently producing an arbitrary order.
