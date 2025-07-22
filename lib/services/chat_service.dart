import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_openai_stream/env.dart';

class ChatService {
  static const String _apiKey = geminiApiKey;

  static Stream<String> getChatResponse({
    required String userMessage,
    Uint8List? imageBytes,
  }) async* {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
    );

    // Explicitly define the body structure with proper typing
    final Map<String, dynamic> body = {
      "contents": [
        {
          "parts": <Map<String, dynamic>>[
            if (userMessage.isNotEmpty) {"text": userMessage},
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 2048,
      }
    };

    // Add image to request if provided
    if (imageBytes != null) {
      try {
        if (imageBytes.isEmpty) {
          yield 'Error: Empty image data provided';
          return;
        }
        final base64Image = base64Encode(imageBytes);
        (body["contents"] as List<dynamic>)[0]["parts"].add({
          "inlineData": {
            "mimeType": "image/jpeg",
            "data": base64Image
          }
        });
      } catch (e) {
        yield 'Error: Failed to process image data. Details: $e';
        return;
      }
    }

    try {
      // Debug: Log the request body
      print('Request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // Debug: Log the response status and body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data["candidates"] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]["content"]["parts"] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]["text"] as String?;
            if (text != null) {
              // Stream by sentences for better readability
              final sentences = _splitIntoSentences(text);
              for (var sentence in sentences) {
                await Future.delayed(const Duration(milliseconds: 100));
                yield sentence;
              }
            } else {
              yield 'Error: No valid text response in candidates';
            }
          } else {
            yield 'Error: No valid parts in response';
          }
        } else {
          yield 'Error: No valid candidates in response';
        }
      } else {
        yield 'Error: Unable to get response from AI service. Status: ${response.statusCode}';
      }
    } catch (e) {
      yield 'Error: Connection failed. Please check your internet connection.\nDetails: $e';
    }
  }

  static List<String> _splitIntoSentences(String text) {
    if (text.isEmpty) return [];

    final chunks = <String>[];
    final words = text.split(' ');

    String currentChunk = '';
    for (var word in words) {
      currentChunk += '$word ';

      // Create chunks of reasonable size (about 5-8 words)
      if (currentChunk.split(' ').length >= 6 ||
          word.endsWith('.') ||
          word.endsWith('!') ||
          word.endsWith('?') ||
          word.endsWith(':')) {
        chunks.add(currentChunk.trim());
        currentChunk = '';
      }
    }

    // Add any remaining text
    if (currentChunk.trim().isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks.map((chunk) => '$chunk ').toList();
  }
}