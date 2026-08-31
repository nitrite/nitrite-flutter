## 3.3.0

- `BoxMap.valuesSkipping` reaches a page's offset by stepping over the box's keys instead of reading and decoding every document in front of it. The box keeps its keys in memory and its values on disk, so stepping a key is an iterator bump where reading one is a read and a decode - which was the whole cost of a late page. Paging 20k rows of ~1KB, 400 to a page, went from 27.6x the duration of one full scan to 1.0x.
  - Advanced by hand rather than with `Iterable.skip`, which keeps calling `moveNext` for the whole count without looking at what it returns: Hive's skip-list iterator dereferences a null once past the end, so a page starting beyond the last key threw instead of coming back empty.
- Requires `nitrite ^3.3.0`, which is where `valuesSkipping` is introduced.
- The version stamper (`test/hive_test.dart`) no longer needs a Flutter engine, for the same reason as in `nitrite`.

## 3.2.0

- Rebuilt against nitrite 3.2.0. No functional change in this package.

## 3.1.0

- Maintenance release: raised `nitrite` dependency to `^3.1.0`.

## 3.0.0

- Maintenance release: raised `nitrite` dependency to `^3.0.0`, which drops the no-op `distinct` find option.

## 2.1.0

- Maintenance release: raised `nitrite` dependency to `^2.1.0`.

## 2.0.4

- Maintenance release: raised `nitrite` dependency to `^2.0.4`.

## 2.0.3

- Maintenance release: raised `nitrite` dependency to `^2.0.3`.

## 2.0.1

- Spatial queries on the Hive store now use an in-memory packed R-tree hydrated from the durable box, replacing the per-query linear key scan with `O(log n + result)` lookups. Query results are unchanged.

## 2.0.0

* **BREAKING CHANGE**: Upgraded minimum Dart SDK to 3.5.0 and migrated to Dart Workspaces to support Melos 8.

## 1.1.3

- Renamed the `isSorted` test helper to avoid a name collision with the latest `matcher` package so the test suite compiles in CI.

## 1.1.2

- Raised the minimum `nitrite` dependency to `1.1.1`, which is required for `IndexKey`.

## 1.1.1

- Added support for composite indexing via `IndexKey`.
- Updated Nitrite to 1.1.1.

## 1.1.0

- Updated Nitrite to 1.1.0.

## 1.0.3

- Updated Nitrite to 1.0.3.
- Updated some dependencies.

## 1.0.2

- Updated Nitrite to 1.0.2.

## 1.0.1

- Minor documentation updates.
- Example code updated.

## 1.0.0

- Initial version.