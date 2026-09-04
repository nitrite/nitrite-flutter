## Unreleased

Ported from the corresponding fixes in `nitrite-java`, where each was found.

- A unique index no longer rejects a document over a key that document already holds. `addNitriteIds` treated *any* existing id under the key as a violation, so it counted the writer's own id against it. That bites a unique index over an array field with a repeated element - `['a', 'b', 'a']` visits `a` twice, and the second visit collided with the entry the first had just written - and any path that reaches a key the document already owns, such as an index rebuild or a replayed write. Another document under the key is still a violation. (nitrite/nitrite-java#1295)
- An update that leaves an indexed value unchanged no longer rewrites the index. `DocumentIndexWriter.updateIndexEntry` treated an index as affected whenever the update document carried the indexed field, and then removed and rewrote the entry. An update that writes the whole document back - the common upsert shape - carries every indexed field with its old value, so every index was rebuilt on every update for nothing. The old and new values are now compared with `deepEquals`, and the index is left alone when they match. A dirty index is still rebuilt, since that has to happen on the first write regardless. (nitrite/nitrite-java#1297)
- `MapMetaData` copies the stored name set instead of adopting it. `document[tagMapMetaData]?.cast<String>()` returns a *view* onto the set held in the catalog document, so `mapNames.add(name)` edited the stored set in place - before the write that was supposed to record it, and past any rollback. It now takes a copy, so a write always stores a new set. (nitrite/nitrite-java#1296)

## 3.3.0

- Paging a collection no longer pays for the documents it skips past. `skip` was applied by pulling and discarding, and on a persistent store each discarded row had already been read off disk and decoded, so a page-by-page lap over 20k rows of ~1KB cost 27.6x a single full scan of the same collection - 19.8 seconds against 0.7. The offset is now taken at the source: `NitriteMap.valuesSkipping` steps over keys without reading the values behind them, and an index plan skips its ids before they turn into document reads. The same lap now costs 1.0x - what one full scan costs.
  - `valuesSkipping` is defaulted to the old discard, so a store implementation outside this repository stays correct without changing anything. A store whose keys can be walked without reading values should override it.
  - The push-down is declined where anything between the source and the page drops or reorders rows - a scanned filter, a blocking sort, an `or` plan. Those keep the stream skip, which is correct and merely pays for what it passes over. Note that an unfiltered scan carries the `all` filter rather than `null`, and that one accepts every document, so it moves no row past the offset.
- The version stamper (`test/nitrite_test.dart`) no longer needs a Flutter engine. It read `pubspec.yaml` through `rootBundle`, which meant `WidgetsFlutterBinding` and `package:flutter`, so it could only be compiled by `flutter test`; under `dart test` it crashed the Dart front end in the FFI transformer and took every file compiled alongside it down too. It reads the file with `dart:io` now and runs under either. It also no longer writes trailing whitespace that dirtied the working tree on every run.

## 3.2.0

- Added `Transaction.viewOf`, a transactional view over a collection the caller already holds. `getCollection(name)` opens the primary by name and refuses a name that is not a collection — and a repository's document collection is not one — so a caller holding an `ObjectRepository.documentCollection`, and no `T` to reach `getRepository` with, had no way in. That caller is `nitrite_bridge`, which is handed document collections and knows nothing about the entity types behind them. Keyed by the collection's own name, so asking twice returns the same transactional collection `getCollection` would.

## 3.1.0

- A sorted, limited `find` no longer fetches the whole collection when the sort field is indexed. `find(findOptions: orderBy("createdAt", SortOrder.descending).setLimit(20))` asked for 20 rows and cost what draining every stored document costs: `SortedDocumentStream` collects the entire result set before `skip`/`take` get to drop 99% of it, and the cost is the decode, not the comparison, so it scales with document *size* as well as count. An index on the sort field bought nothing - the index was only ever used to *filter*, never to order, and page 50 cost exactly what page 1 cost because the work finished before the skip applied.
- When the query has no filter, one sort field, a limit, and a simple unique or non-unique index on exactly that field, the sort keys are now read from that index - which already stores them - and only the documents actually returned are fetched. Measured on the Hive adapter over 2000 rows each carrying a 150-element list, a `setLimit(20)` page went from ~342 ms to ~5 ms; over lean rows it went from ~67 ms to ~7 ms.
- The index is used only when it holds exactly one entry per stored document. A multi-valued field is indexed once per element and a non-comparable value is not indexed at all, so both are detected (by a duplicate-id check and an entry-count check) and fall back to the blocking sort. Ordering - including where nulls sort - is identical either way: the same comparator runs over keys taken from the index instead of from the documents.
- New API, all additive: `FindPlan.sortIndexDescriptor`, `NitriteIndex.readSortKeys(int)` and `NitriteIndexer.readSortKeys(IndexDescriptor, NitriteConfig, int)` (both default-implemented to return `null`, so existing indexer plugins are unaffected), and `SortedDocumentStream.compareSortValues(dynamic, dynamic)`.

## 3.0.0

- **BREAKING CHANGE**: Removed the `distinct` find option - the `distinct()` factory, `FindOptions.distinct`, `FindOptions.withDistinct()`, and `FindPlan.distinct`. It had no effect on the result set. A find never returns the same document twice, and the only place the flag was ever read was the `or` sub-stream union, which now deduplicates unconditionally (see below) because an `or` is a set union by definition. The flag's sole remaining effect was to paper over the duplicate defect fixed in this release. Callers passing `distinct()` can drop it without any change in results.
- Fixed `find` returning a document more than once from an `or` filter when the document satisfies more than one branch and every branch is index-backed. The per-branch index scans were concatenated into the result, but the concatenation was only deduplicated if the caller passed the `distinct()` find option, which defaulted to off. An `or` is a set union by definition, so the branches are now always deduplicated by `NitriteId`. The planner path that falls back to a single collection scan when a branch has no index was already correct here (unlike nitrite-rust, where both halves were broken).

## 2.1.0

- Added an `exists` filter. `where("nick").exists()` matches the documents which have the field, irrespective of its value; `where("nick").exists().not()` (or `~where("nick").exists()`) matches those which do not. Also available as a string extension: `"nick".exists()`.
- A field explicitly set to null is present and matches. This is the case no existing filter could express: `eq(null)` and `notEq(null)` cannot tell a missing field apart from one holding null, so "has this document been given a value for this field at all" was not answerable.
- The filter deliberately does not extend `ComparableFilter` and so always runs as a collection scan. A missing field and a field holding null are stored under the same null key in an index, so an index scan could not tell them apart and would disagree with a collection scan.
- Embedded fields are addressed by their dotted path (`where("address.city").exists()`), the same way `Document.containsField` resolves them.

## 2.0.4

- Fixed `field.eq(x)` / `field.within(..)` on an array (list) field silently matching nothing when the filter runs as a collection scan. Array membership is matched element-wise on the index path but was matched by whole-value equality (`deepEquals`) on the collection-scan path, so results depended on whether an index existed or was chosen by the planner. Combined with the 2.0.3 planner change (mirror of nitrite-java [#1266](https://github.com/nitrite/nitrite-java/issues/1266)) — which correctly relegates the non-winning-index filter to a collection scan — an AND of an indexed array `eq` and a bounded range on a second indexed field left the array `eq` running as a collection scan, where it matched no documents. `EqualsFilter` and `_InFilter` now match an array/`Iterable` field by element containment on the collection-scan path, mirroring `applyOnIndex`.

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