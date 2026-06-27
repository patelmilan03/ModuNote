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
  RemoteNoteService({String? baseUrl, String? apiKey})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000/api/v1',
            ),
        _apiKey = apiKey ?? const String.fromEnvironment('API_KEY');

  final String _baseUrl;
  final String _apiKey;

  /// Request headers. Includes the single-user `X-API-Key` when configured
  /// (required by the deployed backend; empty/omitted for local DEV_MODE).
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      };

  /// Suggests up to 5 lowercase tags for a note based on its title and content.
  /// [existingTags] (tag names already on the note) are excluded server-side.
  Future<List<String>> suggestTags({
    required String noteId,
    required String title,
    required String content,
    List<String> existingTags = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/notes/$noteId/tags/suggest');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'content': content,
          'existing_tags': existingTags,
        }),
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

  /// Summarises a note's content into 1-3 sentences.
  Future<String> summariseNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/notes/$noteId/summary');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
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

  /// Runs a writing action on the note text via the backend → Gemini.
  /// [action] is one of: improve, humanize, paraphrase, script, critique.
  /// [tags] are human-readable tag names passed as context.
  Future<String> assist({
    required String noteId,
    required String action,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/notes/$noteId/assist');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'action': action,
          'title': title,
          'content': content,
          'tags': tags,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['result'] as String;
      }
      throw RemoteServiceException('assist failed: ${response.statusCode}');
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('assist network error', cause: e);
    }
  }

  /// Transcribes an audio file via the backend → Groq Whisper (VTT fallback).
  /// Sends the file as multipart; returns the transcript text.
  Future<String> transcribe({required String filePath}) async {
    final uri = Uri.parse('$_baseUrl/notes/transcribe');
    try {
      final request = http.MultipartRequest('POST', uri);
      if (_apiKey.isNotEmpty) request.headers['X-API-Key'] = _apiKey;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['text'] as String;
      }
      throw RemoteServiceException('transcribe failed: ${response.statusCode}');
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('transcribe network error', cause: e);
    }
  }
}
