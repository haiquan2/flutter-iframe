import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'dart:html' as html;

class WebFile {
  final html.File _file;
  WebFile(this._file);

  String get name => _file.name;
  int get size => _file.size;

  Future<Uint8List> readAsBytes() async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(_file);
    await reader.onLoad.first;
    return reader.result as Uint8List;
  }
}

class ChatService {
  static const String baseUrl = 'https://wm5090.pythera.ai/appv2';
  static const String sessionsUrl = 'https://wm5090.pythera.ai/appv1/api/v1/sessions/';
  static final Uuid _uuid = Uuid();
  static String? _sessionId;

  // Tự động tạo session
  static Future<String?> _createSession() async {
    try {
      final userId = _uuid.v4();
      final dio = Dio();
      final response = await dio.post(
        sessionsUrl,
        data: {
          "user_id": userId,
          "expires_in_hours": 24,
          "metadata": {},
          "temp_collection_name": "temp_${userId.substring(0, 8)}"
        },
        options: Options(headers: {'accept': 'application/json', 'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200) {
        final sessionId = response.data['session_id'] as String?;
        _sessionId = sessionId;
        print('Session created: $sessionId');
        return sessionId;
      }
    } catch (e) {
      print('Session creation error: $e');
    }
    return null;
  }

  // Chọn file
  static Future<List<WebFile>?> pickFiles() async {
    final html.InputElement input = html.InputElement(type: 'file');
    input.multiple = true;
    input.accept = '.pdf,.doc,.docx,.txt,.csv';
    input.click();
    await input.onChange.first;
    if (input.files != null && input.files!.isNotEmpty) {
      return input.files!.map((file) => WebFile(file)).toList();
    }
    return null;
  }

  // Upload files với streaming response
  static Stream<String> uploadFilesStream({
    required String question,
    List<WebFile>? files,
  }) async* {
    if (_sessionId == null) {
      await _createSession();
      if (_sessionId == null) {
        yield 'Error: Không tạo được session';
        return;
      }
    }

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'question': question.trim().isEmpty ? 'Phân tích file này' : question.trim(),
        'session_id': _sessionId!,
        'language': 'vi',
        'rerank': 'false',
      });

      if (files != null) {
        for (var file in files) {
          final fileBytes = await file.readAsBytes();
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(
              fileBytes, 
              filename: file.name, 
              contentType: MediaType.parse('application/octet-stream')
            ),
          ));
        }
      }

      final response = await dio.post(
        '$baseUrl/questions',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final answer = response.data['answer']?.toString() ?? 'Xin lỗi, không có phản hồi';
        
        // Stream từng chunk
        final chunks = _splitText(answer);
        for (var chunk in chunks) {
          await Future.delayed(const Duration(milliseconds: 50));
          yield chunk;
        }
      } else {
        yield 'Error: ${response.statusCode}';
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  // Upload files không streaming (trả về ngay)
  static Future<String?> uploadFiles({
    required String question,
    List<WebFile>? files,
  }) async {
    String result = '';
    await for (final chunk in uploadFilesStream(question: question, files: files)) {
      result += chunk;
    }
    return result;
  }

  // Split text thành chunks cho streaming effect
  static List<String> _splitText(String text) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    final chunks = <String>[];
    var currentChunk = StringBuffer();

    for (var sentence in sentences) {
      if (currentChunk.length + sentence.length > 100) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk.clear();
        }
      }
      currentChunk.write(currentChunk.isEmpty ? sentence : ' $sentence');
    }
    if (currentChunk.isNotEmpty) chunks.add(currentChunk.toString());
    
    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  // Utils
  static void clearSession() => _sessionId = null;
  static String? get currentSessionId => _sessionId;
  
  static String formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
