import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../../data/models/qna_answer.dart';

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
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000/api/v1',
            );

  final String _baseUrl;

  /// The current user's Firebase ID token, or null if signed out / Firebase
  /// isn't ready (e.g. in unit tests). Never throws.
  Future<String?> _idToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// JSON request headers. Sends the Firebase ID token as `Authorization:
  /// Bearer` — the backend verifies it and scopes every RAG call to that user
  /// (per-tenant isolation).
  Map<String, String> _jsonHeaders(String? token) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// Builds the exception for a non-200 response, carrying the status code and
  /// the backend's `detail` message (which names the failing provider) so the
  /// UI can say WHAT broke instead of a generic "unavailable".
  RemoteServiceException _httpFailure(String operation, http.Response response) {
    String? detail;
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['detail'] is String) {
        detail = data['detail'] as String;
      }
    } catch (_) {
      // Non-JSON error body (proxy/HTML error page) — no detail to surface.
    }
    return RemoteServiceException(
      '$operation failed: ${response.statusCode}',
      statusCode: response.statusCode,
      detail: detail,
    );
  }

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
        headers: _jsonHeaders(await _idToken()),
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
      throw _httpFailure('suggestTags', response);
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
        headers: _jsonHeaders(await _idToken()),
        body: jsonEncode({'title': title, 'content': content}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['summary'] as String;
      }
      throw _httpFailure('summariseNote', response);
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
        headers: _jsonHeaders(await _idToken()),
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
      throw _httpFailure('assist', response);
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('assist network error', cause: e);
    }
  }

  /// Indexes a note's plain text into the backend vector store (RAG, Stage 2).
  /// Called when an indexable note (tagged study/notes/research) is saved/closed.
  /// Returns the number of chunks stored. Empty content deindexes server-side.
  Future<int> indexNote({
    required String noteId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/index/notes');
    try {
      final response = await http.post(
        uri,
        headers: _jsonHeaders(await _idToken()),
        body: jsonEncode({
          'note_id': noteId,
          'title': title,
          'content': content,
          'tags': tags,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['chunks_indexed'] as int? ?? 0;
      }
      throw _httpFailure('indexNote', response);
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('indexNote network error', cause: e);
    }
  }

  /// Removes a note's chunks from the backend vector store (RAG, Stage 2).
  /// Called when a note loses all trigger tags or is deleted.
  Future<void> deindexNote({required String noteId}) async {
    final uri = Uri.parse('$_baseUrl/index/notes/$noteId');
    try {
      final response =
          await http.delete(uri, headers: _jsonHeaders(await _idToken()));
      // 204 = removed; 404 = nothing indexed (already gone) — both are fine.
      if (response.statusCode == 204 || response.statusCode == 404) return;
      throw _httpFailure('deindexNote', response);
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('deindexNote network error', cause: e);
    }
  }

  /// Asks a natural-language question grounded in the indexed notes (RAG QnA).
  /// Returns the answer plus the source notes it cited.
  Future<QnaAnswer> ask({required String question}) async {
    // The web portfolio build (no login) asks the public, read-only demo
    // dataset; native asks the signed-in user's own notes (token-scoped).
    final uri = Uri.parse('$_baseUrl${kIsWeb ? '/qna/demo' : '/qna'}');
    try {
      final headers = kIsWeb
          ? const {'Content-Type': 'application/json'}
          : _jsonHeaders(await _idToken());
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'question': question}),
      );
      if (response.statusCode == 200) {
        return QnaAnswer.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw _httpFailure('ask', response);
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('ask network error', cause: e);
    }
  }

  /// Transcribes an audio file via the backend → Groq Whisper (VTT fallback).
  /// Sends the file as multipart; returns the transcript text.
  Future<String> transcribe({required String filePath}) async {
    final uri = Uri.parse('$_baseUrl/notes/transcribe');
    try {
      final request = http.MultipartRequest('POST', uri);
      final token = await _idToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['text'] as String;
      }
      throw _httpFailure('transcribe', response);
    } on RemoteServiceException {
      rethrow;
    } catch (e) {
      throw RemoteServiceException('transcribe network error', cause: e);
    }
  }
}
