/// Support for doing something awesome.
///
/// More dartdocs go here.
library nitrite;

export 'src/nitrite_base.dart';
export 'src/nitrite_builder.dart';
export 'src/nitrite_config.dart';

export 'src/collection/index.dart';
export 'src/collection/events/index.dart';

export 'src/store/nitrite_store.dart';
export 'src/store/meta_data.dart' hide MapMetaData;
export 'src/store/store_meta_data.dart';
export 'src/store/store_config.dart';
export 'src/store/nitrite_map.dart';
export 'src/store/nitrite_rtree.dart';
export 'src/store/events/events.dart';

export 'src/repository/object_repository.dart';

export 'src/transaction/session.dart';

export 'src/common/exception/exceptions.dart';
export 'src/common/fields.dart';
export 'src/common/module/nitrite_module.dart';
export 'src/common/module/nitrite_plugin.dart';
export 'src/common/module/plugin_manager.dart';

export 'src/common/mapper/nitrite_mapper.dart';

export 'src/common/record_stream.dart';
export 'src/common/tuples/tuples.dart';
export 'src/common/processors/processor.dart';

export 'src/migration/migration.dart';

export 'src/index/index.dart';

export 'src/filters/filter.dart';
export 'src/filters/filter_extension.dart';
