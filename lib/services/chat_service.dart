import 'dart:async';
import 'dart:convert';
import 'package:flutter_openai_stream/env.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiKey = geminiApiKey; 

  static Stream<String> getChatResponse(String userMessage) async* {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$_apiKey',
    );

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": userMessage}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 2048,
      }
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data["candidates"];
        
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]["content"]["parts"][0]["text"] as String;
          
          // Stream by sentences for better readability
          final sentences = _splitIntoSentences(text);
          
          for (var sentence in sentences) {
            await Future.delayed(const Duration(milliseconds: 100));
            yield sentence;
          }
        }
      } else {
        yield 'Error: Unable to get response from AI service. Status: ${response.statusCode}';
      }
    } catch (e) {
      yield 'Error: Connection failed. Please check your internet connection.\nDetails: $e';
    }
  }

  static List<String> _splitIntoSentences(String text) {
    // Split text into smaller chunks for streaming
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
