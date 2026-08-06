/// The Nitrite adapter for `dbinspect_bridge`.
///
/// The bridge core — the wire protocol, pairing, the WebSocket transport and
/// the release-build guard — lives in `dbinspect_bridge` and is engine-neutral.
/// This package adds the piece that knows about Nitrite, so that inspecting a
/// Nitrite database pulls in Nitrite and nothing else, and inspecting a SQLite
/// or Drift database pulls in no Nitrite at all.
///
/// ```dart
/// final bridge = await startBridge(
///   appName: 'my_app',
///   adapters: [NitriteAdapter(db, id: 'main', displayName: 'app data')],
/// );
/// ```
///
/// In a release build that call returns `null` and the server is not in the
/// binary at all — see `bridgeEnabled` in `dbinspect_bridge`.
library;

export 'package:dbinspect_bridge/dbinspect_bridge.dart';

export 'src/filter_dsl.dart'
    show maxFilterDepth, maxRegexPatternLength, nitriteFilterOps;
export 'src/nitrite_adapter.dart';
