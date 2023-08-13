/// An interface to be implemented by a dart class which
/// supports a special initialization method
abstract class Initializable {
  /// Initializes the object
  Future<void> initialize();
}
