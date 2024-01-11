# Nitrite Spatial

Nitrite Spatial is a spatial indexing and search module for Nitrite database. It uses JTS Topology Suite port of the dart package [dart_jts](https://pub.dev/packages/dart_jts) for spatial indexing and search.

## Getting started

To use Nitrite Spatial, add the following dependency in your project:

```bash
dart pub add nitrite_spatial
```

## Usage

To use Nitrite Spatial, you need to create a `SpatialModule` and pass it to Nitrite builder. 

```dart
// create a spatial module
var spatialModule = SpatialModule();

// initialization using builder
var db = await Nitrite.builder()
    .loadModule(spatialModule)
    .openOrCreate(username: 'user', password: 'pass123');

```

## Additional information

For additional information visit the Spatial module [documentation](https://nitrite.dizitart.com/flutter-sdk/modules/spatial/index.html).