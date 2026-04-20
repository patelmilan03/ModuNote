import 'package:equatable/equatable.dart';

/// Domain model for a tag.
/// Tags are freeform, stored lowercase, many-to-many with notes.
class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;

  /// Always lowercase. Normalised on write via StringExtensions.normalised.
  final String name;

  final DateTime createdAt;

  Tag copyWith({String? id, String? name, DateTime? createdAt}) => Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, createdAt];
}
