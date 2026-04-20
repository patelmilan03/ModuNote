import 'package:uuid/uuid.dart';

/// Thin wrapper around the uuid package.
/// Centralised so the UUID version (v4) is only decided in one place.
class UuidGenerator {
  const UuidGenerator._();

  static final _uuid = const Uuid();

  /// Generates a new random UUID v4 string.
  static String generate() => _uuid.v4();
}
