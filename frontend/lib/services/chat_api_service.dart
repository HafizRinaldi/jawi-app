import 'dart:convert';
import 'package:http/http.dart' as http;

/// A service class to handle all network communication with the Python backend.
class ChatApiService {
  // The base URL of the backend server.
  static const String _baseUrl = 'https://Manok45-jawi-backendv2.hf.space';

  /// Fetches a response from the main factual/RAG chat endpoint.
  ///
  /// Sends the user's [query], optional initial [context] (like a letter name),
  /// and the recent conversation [history] to get a context-aware answer.
  static Future<String> getChatResponse(
    String query, {
    String? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'context': context,
          'history':
              history ?? [], // Pass history to maintain conversation context.
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? 'Sorry, an error occurred.';
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return 'Error ${response.statusCode}: ${error['error']}';
      }
    } catch (e) {
      return 'Failed to connect to the server. Please ensure the backend is running.';
    }
  }

  /// Fetches a response from the creative/generative chat endpoint.
  ///
  /// This is used for tasks that don't rely on the factual knowledge base,
  /// such as creating new examples or translating words.
  static Future<String> getCreativeResponse(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat-creative'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? 'Sorry, an error occurred.';
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return 'Error ${response.statusCode}: ${error['error']}';
      }
    } catch (e) {
      return 'Failed to connect to the server. Please ensure the backend is running.';
    }
  }
}
