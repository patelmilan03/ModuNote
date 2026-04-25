import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../repositories/interfaces/i_category_repository.dart';
import '../../repositories/interfaces/i_note_repository.dart';
import '../../repositories/interfaces/i_tag_repository.dart';
import '../../repositories/local/local_category_repository.dart';
import '../../repositories/local/local_note_repository.dart';
import '../../repositories/local/local_tag_repository.dart';
import 'app_database.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(AppDatabase.createExecutor());
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
INoteRepository noteRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalNoteRepository(db.notesDao);
}

@Riverpod(keepAlive: true)
ITagRepository tagRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalTagRepository(db.tagsDao);
}

@Riverpod(keepAlive: true)
ICategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalCategoryRepository(db.categoriesDao);
}
