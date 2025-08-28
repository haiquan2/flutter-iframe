import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
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

class FileUploadService {
  static const String baseUrl = 'https://wm5090.pythera.ai/appv2';
  
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
  
  static Future<String?> uploadFiles({
    required String question,
    required String sessionId,
    List<WebFile>? files,
  }) async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'question': question,
        'session_id': sessionId,
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
              contentType: MediaType.parse('application/octet-stream'),
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
        return response.data['answer'];
      }
      return 'Error: ${response.statusCode}';
    } catch (e) {
      return 'Error: $e';
    }
  }
}