## 2.0.4

- Maintenance release: raised `nitrite` dependency to `^2.0.4`.

## 2.0.3

- Maintenance release: raised `nitrite` dependency to `^2.0.3`.

## 2.0.1

- Spatial queries (intersects/within/nearest) now run on a packed R-tree provided by `nitrite` and `nitrite_hive_adapter` 2.0.1, replacing the per-query linear scan with `O(log n + result)` lookups. Query results are unchanged.
- Raised `nitrite`, `nitrite_hive_adapter` and `nitrite_generator` dependencies to `^2.0.1`.

## 2.0.0

* **BREAKING CHANGE**: Upgraded minimum Dart SDK to 3.5.0 and migrated to Dart Workspaces to support Melos 8.

## 1.1.3

- Added the `test` dev dependency so the package test suite compiles and runs in CI.

## 1.1.2

- Reformatted the source with the latest Dart formatter.

## 1.1.1

- Added `geoNear` and `kNearest` spatial filters.
- Fixed false positives in the `intersects` filter by adding post-index validation.
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
- Example code added.
- `geometryEquals` method is public now.

## 1.0.0

- Initial version.