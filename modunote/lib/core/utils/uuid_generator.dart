import 'package:uuid/uuid.dart';

/// Thin wrapper around the uuid package.
/// Centralised so the UUID version (v4) is only decided in one place.
class UuidGenerator {
  const UuidGenerator._();

  static const _uuid = Uuid();

  /// Generates a new random UUID v4 string.
  static String generate() => _uuid.v4();
}
