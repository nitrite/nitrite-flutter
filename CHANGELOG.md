# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-07-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`nitrite` - `v2.1.0`](#nitrite---v210)
 - [`nitrite_generator` - `v2.1.0`](#nitrite_generator---v210)
 - [`nitrite_hive_adapter` - `v2.1.0`](#nitrite_hive_adapter---v210)
 - [`nitrite_spatial` - `v2.1.0`](#nitrite_spatial---v210)
 - [`nitrite_support` - `v2.1.0`](#nitrite_support---v210)
 - [`nitrite_demo` - `v2.0.1`](#nitrite_demo---v201)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `nitrite_demo` - `v2.0.1`

---

#### `nitrite` - `v2.1.0`

 - **FIX**: null handling in index range scans and blocking sort, in filter index lookups (v2.0.2). ([a675914f](https://github.com/nitrite/nitrite-flutter/commit/a675914fa59b955a214fbdfc4dad9bc44fddf1f4))
 - **FIX**(spatial): add test dev dependency to fix CI build. ([4b9b499c](https://github.com/nitrite/nitrite-flutter/commit/4b9b499cadadfd8f615ede29ede588f476f96b52))
 - **FEAT**(spatial): packed R-tree for spatial index, release 2.0.1. ([50ad30d7](https://github.com/nitrite/nitrite-flutter/commit/50ad30d7bce6d3de1d388677ea91632d6be91fde))
 - **FEAT**: implement NitriteIsolate for concurrent database access across multiple isolates and enhance composite indexing functionality. ([8161760c](https://github.com/nitrite/nitrite-flutter/commit/8161760c876e4df6aced4558db4ea06a4e40a428))
 - **FEAT**: implement composite indexing with IndexKey and update related functionality. ([42dc944a](https://github.com/nitrite/nitrite-flutter/commit/42dc944ac9cebaf943a286a4f562635d2c4ef693))
 - **FEAT**: add count method to DocumentCursor and Cursor for efficient document counting. ([994c31a7](https://github.com/nitrite/nitrite-flutter/commit/994c31a7c94b456eac2765a2200968a1dfab4745))

#### `nitrite_generator` - `v2.1.0`

 - **FEAT**(spatial): packed R-tree for spatial index, release 2.0.1. ([50ad30d7](https://github.com/nitrite/nitrite-flutter/commit/50ad30d7bce6d3de1d388677ea91632d6be91fde))

#### `nitrite_hive_adapter` - `v2.1.0`

 - **FIX**(hive_adapter): rename isSorted test helper to fix CI build. ([409c829f](https://github.com/nitrite/nitrite-flutter/commit/409c829f3e730468af58d168b320c80341eabc77))
 - **FIX**(spatial): add test dev dependency to fix CI build. ([4b9b499c](https://github.com/nitrite/nitrite-flutter/commit/4b9b499cadadfd8f615ede29ede588f476f96b52))
 - **FEAT**(spatial): packed R-tree for spatial index, release 2.0.1. ([50ad30d7](https://github.com/nitrite/nitrite-flutter/commit/50ad30d7bce6d3de1d388677ea91632d6be91fde))
 - **FEAT**: implement NitriteIsolate for concurrent database access across multiple isolates and enhance composite indexing functionality. ([8161760c](https://github.com/nitrite/nitrite-flutter/commit/8161760c876e4df6aced4558db4ea06a4e40a428))
 - **FEAT**: implement composite indexing with IndexKey and update related functionality. ([42dc944a](https://github.com/nitrite/nitrite-flutter/commit/42dc944ac9cebaf943a286a4f562635d2c4ef693))
 - **FEAT**: add count method to DocumentCursor and Cursor for efficient document counting. ([994c31a7](https://github.com/nitrite/nitrite-flutter/commit/994c31a7c94b456eac2765a2200968a1dfab4745))

#### `nitrite_spatial` - `v2.1.0`

 - **FIX**(spatial): add test dev dependency to fix CI build. ([4b9b499c](https://github.com/nitrite/nitrite-flutter/commit/4b9b499cadadfd8f615ede29ede588f476f96b52))
 - **FEAT**(spatial): packed R-tree for spatial index, release 2.0.1. ([50ad30d7](https://github.com/nitrite/nitrite-flutter/commit/50ad30d7bce6d3de1d388677ea91632d6be91fde))
 - **FEAT**: add count method to DocumentCursor and Cursor for efficient document counting. ([994c31a7](https://github.com/nitrite/nitrite-flutter/commit/994c31a7c94b456eac2765a2200968a1dfab4745))

#### `nitrite_support` - `v2.1.0`

 - **FEAT**(spatial): packed R-tree for spatial index, release 2.0.1. ([50ad30d7](https://github.com/nitrite/nitrite-flutter/commit/50ad30d7bce6d3de1d388677ea91632d6be91fde))

