import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_openai_stream/env.deploy.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'dart:html' as html;

// User info model
class UserInfo {
  final String? username;
  final String? name; 
  final String? birthday;
  final String? sessionId;
  
  UserInfo({this.username, this.name, this.birthday, this.sessionId});
  
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      username: map['username']?.toString() ?? 
                map['email']?.toString().split('@')[0], // Fallback to email prefix if no username
      name: map['name']?.toString() ?? 
            map['displayName']?.toString(), // Support both name and displayName
      birthday: map['dob']?.toString() ?? 
                map['birthday']?.toString() ?? 
                '20/10/2000', // Default fake birthday if not provided
      sessionId: map['session_id']?.toString(),
    );
  }
}

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
  static const String baseUrl = Env.baseUrl;
  static const String sessionsUrl = Env.sessionsUrl;
  static final Uuid _uuid = Uuid();
  static String? _sessionId;
  static UserInfo? _currentUser;
  static StreamController<UserInfo>? _userStreamController;
  static bool _isListenerInitialized = false; // Flag để đảm bảo chỉ init 1 lần

  // Initialize postMessage listener
  static void initUserDataListener() {
    // Chỉ init 1 lần duy nhất
    if (_isListenerInitialized) {
      print('♻️ ChatService listener already initialized, preserving user: ${_currentUser?.name}');
      return;
    }
    
    _isListenerInitialized = true;
    _userStreamController = StreamController<UserInfo>.broadcast();
    print('🎯 ChatService initialized. Waiting for USER_INFO from parent via postMessage...');
    
    // Log current user state
    if (_currentUser != null) {
      print('💾 Preserved user data: ${_currentUser!.name} (@${_currentUser!.username})');
    }
    
    html.window.onMessage.listen((event) {
      try {
        print('📨 Received postMessage: ${event.data}');
        
        // Handle both string and object data
        Map<String, dynamic>? data;
        
        if (event.data is String) {
          try {
            data = json.decode(event.data);
          } catch (e) {
            print('⚠️ Failed to parse JSON string: $e');
            return;
          }
        } else if (event.data is Map) {
          data = Map<String, dynamic>.from(event.data);
        } else {
          print('⚠️ Unknown message type: ${event.data.runtimeType}');
          return;
        }
        
        if (data != null && data['type'] == 'USER_INFO' && data['payload'] != null) {
          final userInfo = UserInfo.fromMap(Map<String, dynamic>.from(data['payload']));
          _setUserInfo(userInfo);
          print('✅ Successfully processed USER_INFO message');
        } else if (data != null && (data['type'] == 'PING' || data['type'] == 'IFRAME_READY' || data['type'] == 'iframe_ready')) {
          print('🏓 Received ${data['type']} from parent');
        } else {
          print('ℹ️ Ignoring message type: ${data?['type']}');
        }
      } catch (e) {
        print('❌ Error parsing user data: $e');
        print('❌ Raw event data: ${event.data}');
      }
    });
    
    print('🎯 ChatService initialized. Waiting for USER_INFO from parent via postMessage...');
  }

  // Set user info and notify listeners
  static void _setUserInfo(UserInfo userInfo) {
    print('🎭 Setting user info: ${userInfo.name} (@${userInfo.username})');
    _currentUser = userInfo;
    _sessionId = userInfo.sessionId; // Use provided session or keep existing
    _userStreamController?.add(userInfo);
    print('✅ User logged in: ${userInfo.name} (@${userInfo.username}) - Birthday: ${userInfo.birthday}');
  }

  // Get user stream
  static Stream<UserInfo>? get userStream => _userStreamController?.stream;
  static UserInfo? get currentUser {
    print('🔍 Getting currentUser: ${_currentUser?.name}');
    return _currentUser;
  }

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

  // Upload files với streaming response + user data
  static Stream<String> uploadFilesStream({
    required String question,
    List<WebFile>? files,
  }) async* {
    // Debug current user state at the start of upload
    print('🎭 Upload starting - Current user: ${_currentUser?.name} (@${_currentUser?.username})');
    print('🔍 User object details: $_currentUser');
    
    if (_sessionId == null) {
      await _createSession();
      if (_sessionId == null) {
        yield 'Sorry, our system is experiencing issues. Please try again later.';
        return;
      }
    }

    try {
      final dio = Dio();
      // Prepare form data with user info
      final formDataMap = {
        'question': question.trim().isEmpty ? 'Analyze this file' : question.trim(),
        'session_id': _sessionId!,
      };
      
      // Add user info to request if available
      if (_currentUser?.name != null) {
        formDataMap['name'] = _currentUser!.name!;
        print('📝 Adding name: ${_currentUser!.name}');
      }
      if (_currentUser?.username != null) {
        formDataMap['username'] = _currentUser!.username!;
        print('📝 Adding username: ${_currentUser!.username}');
      }
      if (_currentUser?.birthday != null) {
        formDataMap['birthday'] = _currentUser!.birthday!;
        print('📝 Adding birthday: ${_currentUser!.birthday}');
      }
      
      print('📋 Full FormData: $formDataMap');
      final formData = FormData.fromMap(formDataMap);

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

      print('🚀 Sending request with user: ${_currentUser?.name} (@${_currentUser?.username})');

      final response = await dio.post(
        '$baseUrl/lumir/chat/v1',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final answer = response.data['answer']?.toString() ?? 'Sorry, no response available';

        // Stream từng chunk
        final chunks = _splitText(answer);
        for (var chunk in chunks) {
          await Future.delayed(const Duration(milliseconds: 50));
          yield chunk;
        }
      } else {
        yield 'Sorry, our system is experiencing issues. Please try again later.';
      }
    } catch (e) {
      print('❌ Chat error: $e');
      yield 'Sorry, our system is experiencing issues. Please try again later.';
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

  static List<String> _splitText(String text) {
    final List<String> chunks = [];
    int currentIndex = 0;
    const int chunkSize = 30;
    
    while (currentIndex < text.length) {
      int endIndex = currentIndex + chunkSize;
      
      if (endIndex >= text.length) {
        chunks.add(text.substring(currentIndex));
        break;
      }
      
      int spaceIndex = text.lastIndexOf(' ', endIndex);
      if (spaceIndex > currentIndex) {
        endIndex = spaceIndex + 1;
      }
      
      chunks.add(text.substring(currentIndex, endIndex));
      currentIndex = endIndex;
    }
    
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

  static void dispose() {
    _userStreamController?.close();
  }
}