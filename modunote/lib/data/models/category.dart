import 'package:equatable/equatable.dart';

/// Domain model for a category (folder).
/// Uses an adjacency-list hierarchy: [parentId] null = root.
/// Max nesting depth: AppConstants.maxCategoryDepth (5).
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// Null means this is a root-level category.
  final String? parentId;

  /// Used to order siblings. Lower = higher in list.
  final int sortOrder;

  final DateTime createdAt;

  bool get isRoot => parentId == null;

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    int? sortOrder,
    DateTime? createdAt,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId ?? this.parentId,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, parentId, sortOrder, createdAt];
}
