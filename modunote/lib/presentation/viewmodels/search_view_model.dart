import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/note.dart';

part 'search_view_model.g.dart';

/// The 5 most recent notes (by `updatedAt`), shown on the Explore screen when
/// no search query is active. Independent of the home-screen filter.
@riverpod
Stream<List<Note>> recentNotes(Ref ref) {
  return ref.watch(noteRepositoryProvider).watchAll().map((notes) {
    final sorted = [...notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(5).toList();
  });
}

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const AsyncData([]),
  });

  final String query;
  final AsyncValue<List<Note>> results;

  SearchState copyWith({
    String? query,
    AsyncValue<List<Note>>? results,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
      );
}

@riverpod
class SearchViewModel extends _$SearchViewModel {
  Timer? _debounce;

  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void setQuery(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      state = SearchState(query: query, results: const AsyncData([]));
      return;
    }
    state = state.copyWith(query: query, results: const AsyncLoading());
    _debounce = Timer(_debounceDuration, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await ref.read(noteRepositoryProvider).search(query);
      state = state.copyWith(results: AsyncData(results));
    } on AppException catch (e, st) {
      state = state.copyWith(results: AsyncError(e, st));
    }
  }
}
