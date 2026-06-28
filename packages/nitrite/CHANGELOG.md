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