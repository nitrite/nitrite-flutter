## 2.0.3

- Fixed a type-comparison crash (e.g. `InvalidOperationException: Could not compare type int to String`) when an AND filter combined a filter on one indexed field with filters on another, differently-typed indexed field matching a different number of fields (e.g. a single-field index next to a compound index). The query planner picked the best-matching index candidate per field independently but accumulated filters from every candidate it visited into one shared set instead of keeping only the winning index's filters, so filters from an unrelated index leaked into the scan of the chosen index. The planner now selects a single best-matching index and only keeps that index's own filters for the index scan. Mirrors nitrite-java issue [#1266](https://github.com/nitrite/nitrite-java/issues/1266).

## 2.0.2

- Fixed indexed `lt`/`lte` filters returning an empty result when the indexed field contains any null value; the forward index scan now starts from the first non-null key. Mirrors nitrite-java issue [#1262](https://github.com/nitrite/nitrite-java/issues/1262).
- Fixed the blocking sort comparator violating the comparator contract when two documents both have a null sort key, which made `orderBy` results on fields with multiple null values undefined. Mirrors nitrite-java issue [#1261](https://github.com/nitrite/nitrite-java/issues/1261).
- Made `in` filter index scans look up each value directly instead of scanning every index entry, so `in` queries on large indexed collections are now as fast as `eq`. Mirrors nitrite-java issue [#1258](https://github.com/nitrite/nitrite-java/issues/1258).

## 2.0.1

- Replaced the linear-scan spatial R-tree with a Sort-Tile-Recursive packed R-tree, giving `O(log n + result)` window queries (intersects/within) and best-first nearest-neighbour search instead of an `O(n)` scan per query. Query semantics are unchanged.

## 2.0.0

* **BREAKING CHANGE**: Upgraded minimum Dart SDK to 3.5.0 and migrated to Dart Workspaces to support Melos 8.

## 1.1.2

- Widened the `rxdart` dependency constraint to `^0.28.0` to support its latest version.
- Added missing type annotations and corrected doc comments to satisfy the latest analysis rules.
- Reformatted the source with the latest Dart formatter.

## 1.1.1

- Added `NitriteIsolate` for concurrent database access across multiple isolates.
- Added composite (compound) indexing support via `IndexKey`.
- Added `count()` method to `DocumentCursor` and `Cursor` for efficient document counting.
- Added web support by using a web-safe maximum integer value.
- New option added for `NitriteBuilder` to disable repository type validation.
- Database is now auto committed before close.
- Fix for updating values where the value was previously null.
- Fix for `Document.fields` not returning iterable fields.

## 1.1.0

- Enum is supported now for automatic `EntityConverter` generation.
- Issue fix for `getById()` method in `ObjectRepository` for embedded id.

## 1.0.3

- Updated some dependencies.
- Issue fix for restricting multiple indexes on same field(s) in an ObjectRepository.
- Issue fix for sorting on indexed field.

## 1.0.2

- Updated some dependencies.
- Issue fix for readonly mode not being respected when opening an existing collection.
- Optimized the indexing operation during update.

## 1.0.1

- Minor documentation updates.
- Collection change listener subscription is now cancelled when the collection is closed. 


## 1.0.0

- Initial version.