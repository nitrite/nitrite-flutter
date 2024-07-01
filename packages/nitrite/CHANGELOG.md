## 1.1.1

- New options added for `NitriteBuilder` to disable check for repository type.
- Fix for updating values where the value was previously null
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
