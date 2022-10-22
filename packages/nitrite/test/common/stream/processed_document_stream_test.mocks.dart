// Mocks generated by Mockito 5.3.2 from annotations
// in nitrite/test/common/stream/processed_document_stream_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:nitrite/nitrite.dart' as _i2;
import 'package:nitrite/src/common/persistent_collection.dart' as _i5;
import 'package:nitrite/src/common/processors/processor.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeDocument_0 extends _i1.SmartFake implements _i2.Document {
  _FakeDocument_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ProcessorChain].
///
/// See the documentation for Mockito's code generation for more information.
class MockProcessorChain extends _i1.Mock implements _i3.ProcessorChain {
  MockProcessorChain() {
    _i1.throwOnMissingStub(this);
  }

  @override
  List<_i2.Processor> get processors => (super.noSuchMethod(
        Invocation.getter(#processors),
        returnValue: <_i2.Processor>[],
      ) as List<_i2.Processor>);
  @override
  _i4.Future<_i2.Document> processBeforeWrite(_i2.Document? document) =>
      (super.noSuchMethod(
        Invocation.method(
          #processBeforeWrite,
          [document],
        ),
        returnValue: _i4.Future<_i2.Document>.value(_FakeDocument_0(
          this,
          Invocation.method(
            #processBeforeWrite,
            [document],
          ),
        )),
      ) as _i4.Future<_i2.Document>);
  @override
  _i4.Future<_i2.Document> processAfterRead(_i2.Document? document) =>
      (super.noSuchMethod(
        Invocation.method(
          #processAfterRead,
          [document],
        ),
        returnValue: _i4.Future<_i2.Document>.value(_FakeDocument_0(
          this,
          Invocation.method(
            #processAfterRead,
            [document],
          ),
        )),
      ) as _i4.Future<_i2.Document>);
  @override
  void add(_i2.Processor? processor) => super.noSuchMethod(
        Invocation.method(
          #add,
          [processor],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void remove(_i2.Processor? processor) => super.noSuchMethod(
        Invocation.method(
          #remove,
          [processor],
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i4.Future<void> process(_i5.PersistentCollection<dynamic>? collection) =>
      (super.noSuchMethod(
        Invocation.method(
          #process,
          [collection],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);
}
