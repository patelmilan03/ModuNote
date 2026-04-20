import 'package:equatable/equatable.dart';

/// Domain model for a note.
/// Content is stored as Quill Delta JSON (Map<String, dynamic>).
/// Phase 2 will add the Drift table that persists this.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.categoryId,
    this.tagIds = const [],
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.local,
  });

  final String id;
  final String title;

  /// Quill Delta JSON. Stored as a JSON-encoded string in Drift (TEXT column).
  final Map<String, dynamic> content;

  final String? categoryId;
  final List<String> tagIds;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Firebase sync preparation. Default is [SyncStatus.local].
  /// Not used until Phase 10.
  final SyncStatus syncStatus;

  Note copyWith({
    String? id,
    String? title,
    Map<String, dynamic>? content,
    String? categoryId,
    List<String>? tagIds,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        categoryId: categoryId ?? this.categoryId,
        tagIds: tagIds ?? this.tagIds,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  @override
  List<Object?> get props => [
        id, title, content, categoryId, tagIds,
        isPinned, isArchived, createdAt, updatedAt, syncStatus,
      ];
}

/// Firebase sync status. Stub for Phase 10.
enum SyncStatus { local, pending, synced, conflict }
