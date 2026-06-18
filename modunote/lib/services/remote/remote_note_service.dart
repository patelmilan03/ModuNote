import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';

/// HTTP client for the ModuNote FastAPI backend.
///
/// Not a Riverpod provider — plain Dart class owned by the caller.
/// [SyncedNoteRepository] will hold a reference in Phase 12 for AI enrichment.
///
/// Default base URL uses 10.0.2.2 which is the Android emulator's loopback
/// address for the host machine. Override [baseUrl] when testing on a physical
/// device or in production.
class RemoteNoteService {
  RemoteNoteService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://10.0.2.2:8000/api/v1';

  final String _baseUrl;

  /// Suggests up to 5 tags for a note based on its title and plain-text content.
  ///
  /// Not implemented until Phase 12 — server returns 501.
  Future<List<String>> suggestTags({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/notes/$noteId/tags/suggest');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'content': content}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['suggested_tags'] as List);
      }
      throw RemoteServiceException(
        'suggestTags failed: ${response.statusCode}',
      );
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('suggestTags network error', cause: e);
    }
  }

  /// Summarises a note's content into a single paragraph.
  ///
  /// Not implemented until Phase 12 — server returns 501.
  Future<String> summariseNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/notes/$noteId/summary');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'content': content}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['summary'] as String;
      }
      throw RemoteServiceException(
        'summariseNote failed: ${response.statusCode}',
      );
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('summariseNote network error', cause: e);
    }
  }
}
