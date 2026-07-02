## 2.1.0

 - **FIX**(hive_adapter): rename isSorted test helper to fix CI build. ([409c829f](https://github.com/nitrite/nitrite-flutter/commit/409c829f3e730468af58d168b320c80341eabc77))
 - **FIX**(spatial): add test dev dependency to fix CI build. ([4b9b499c](https://github.com/nitrite/nitrite-flutter/commit/4b9b499cadadfd8f615ede29ede588f476f96b52))
 - **FEAT**(spatial): packed R-tree for spatial index, release 2.0.1. ([50ad30d7](https://github.com/nitrite/nitrite-flutter/commit/50ad30d7bce6d3de1d388677ea91632d6be91fde))
 - **FEAT**: implement NitriteIsolate for concurrent database access across multiple isolates and enhance composite indexing functionality. ([8161760c](https://github.com/nitrite/nitrite-flutter/commit/8161760c876e4df6aced4558db4ea06a4e40a428))
 - **FEAT**: implement composite indexing with IndexKey and update related functionality. ([42dc944a](https://github.com/nitrite/nitrite-flutter/commit/42dc944ac9cebaf943a286a4f562635d2c4ef693))
 - **FEAT**: add count method to DocumentCursor and Cursor for efficient document counting. ([994c31a7](https://github.com/nitrite/nitrite-flutter/commit/994c31a7c94b456eac2765a2200968a1dfab4745))

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