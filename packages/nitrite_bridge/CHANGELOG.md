## 0.1.0

- First release. `NitriteAdapter` for `dbinspect_bridge`: collections and
  handed-in repositories as stores, schema inferred from a document sample and
  always flagged as inferred, paging over `FindOptions` skip/limit/orderBy, the
  JSON filter DSL, and watch over Nitrite's collection subscription.
- `capabilities.filterOps` reports `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `in`,
  `notIn` and `text`. **`exists` is absent** — nitrite-flutter has no exists
  filter, and the adapter refuses the operator rather than mistranslating it.
- `regex` is off unless `allowRegex` is set, and refused with a length cap and a
  nested-quantifier check when it is on. Dart's `RegExp` backtracks and a match
  cannot be interrupted, so the default is the mitigation that matters.
- Every client-supplied store name is resolved against the set the adapter
  reported: `Nitrite.getCollection` creates a collection that does not exist.
- Sorting by a field no sampled document carries is refused rather than
  silently producing an arbitrary order.
