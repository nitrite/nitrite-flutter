import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:rxdart/rxdart.dart';

typedef StreamFactory<T> = Stream<T> Function();
typedef FutureFactory<T> = Future<T> Function();

/// @nodoc
class ProcessedDocumentStream extends DeferStream<Document> {
  ProcessedDocumentStream(
      StreamFactory<Document> streamFactory, ProcessorChain processorChain,
      {bool reusable = true})
      : super(
            () => streamFactory()
                .asyncMap((event) => _process(processorChain, event)),
            reusable: reusable);

  static Future<Document> _process(
      ProcessorChain processorChain, Document doc) {
    var cloned = doc.clone();
    return processorChain.processAfterRead(cloned);
  }
}
