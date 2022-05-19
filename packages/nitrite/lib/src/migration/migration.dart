abstract class Migration {
  final int _fromVersion;
  final int _toVersion;

  int get fromVersion => _fromVersion;
  int get toVersion => _toVersion;

  Migration(this._fromVersion, this._toVersion);
}
