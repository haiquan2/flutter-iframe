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
                map['email']?.toString().split('@')[0],
      name: map['name']?.toString() ?? 
            map['displayName']?.toString(),
      birthday: map['dob']?.toString() ?? 
                map['birthday']?.toString() ?? 
                '20/10/2000',
      sessionId: map['session_id']?.toString(),
    );
  }
  
  @override
  String toString() {
    return 'UserInfo(name: $name, username: $username, sessionId: $sessionId)';
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
  
  // Use getters/setters to ensure data persistence
  static String? _sessionId;
  static UserInfo? _currentUserData;
  static StreamController<UserInfo>? _userStreamController;
  static bool _isListenerInitialized = false;
  
  // Backup storage in browser's sessionStorage for persistence
  static const String _userStorageKey = 'chat_user_info';
  static const String _sessionStorageKey = 'chat_session_id';

  // Persistent getters with fallback to browser storage
  static UserInfo? get currentUser {
    // First try in-memory data
    if (_currentUserData != null) {
      return _currentUserData;
    }
    
    // Fallback to browser storage
    try {
      final stored = html.window.sessionStorage[_userStorageKey];
      if (stored != null) {
        final userData = json.decode(stored);
        _currentUserData = UserInfo.fromMap(userData);
        return _currentUserData;
      }
    } catch (e) {
      // Silent fail
    }
    
    return null;
  }

  static String? get currentSessionId {
    if (_sessionId != null) return _sessionId;
    
    // Fallback to browser storage
    _sessionId = html.window.sessionStorage[_sessionStorageKey];
    return _sessionId;
  }

    // Initialize postMessage listener with improved persistence
  static void initUserDataListener() {
    if (_isListenerInitialized) {
      return;
    }
    
    _isListenerInitialized = true;
    _userStreamController = StreamController<UserInfo>.broadcast();
    
    // Restore any existing data from storage
    _restoreFromStorage();
    
    html.window.onMessage.listen((event) {
      try {
        Map<String, dynamic>? data;
        
        if (event.data is String) {
          try {
            data = json.decode(event.data);
          } catch (e) {
            return;
          }
        } else if (event.data is Map) {
          data = Map<String, dynamic>.from(event.data);
        } else {
          return;
        }
        
        if (data != null && data['type'] == 'USER_INFO' && data['payload'] != null) {
          final userInfo = UserInfo.fromMap(Map<String, dynamic>.from(data['payload']));
          _setUserInfo(userInfo);
        }
      } catch (e) {
        // Silent fail
      }
    });
  }

  // Restore data from browser storage
  static void _restoreFromStorage() {
    try {
      final userStored = html.window.sessionStorage[_userStorageKey];
      final sessionStored = html.window.sessionStorage[_sessionStorageKey];
      
      if (userStored != null) {
        final userData = json.decode(userStored);
        _currentUserData = UserInfo.fromMap(userData);
      }
      
      if (sessionStored != null) {
        _sessionId = sessionStored;
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Set user info with persistence to browser storage
  static void _setUserInfo(UserInfo userInfo) {
    // Set in memory
    _currentUserData = userInfo;
    _sessionId = userInfo.sessionId ?? _sessionId;
    
    // Persist to browser storage
    try {
      html.window.sessionStorage[_userStorageKey] = json.encode({
        'username': userInfo.username,
        'name': userInfo.name,
        'birthday': userInfo.birthday,
        'session_id': userInfo.sessionId,
      });
      
      if (_sessionId != null) {
        html.window.sessionStorage[_sessionStorageKey] = _sessionId!;
      }
    } catch (e) {
      // Silent fail
    }
    
    // Notify listeners
    _userStreamController?.add(userInfo);
  }

  // Get user stream
  static Stream<UserInfo>? get userStream => _userStreamController?.stream;

  // Auto create session with better error handling
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
        options: Options(
          headers: {'accept': 'application/json', 'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200) {
        final sessionId = response.data['session_id'] as String?;
        _sessionId = sessionId;
        
        // Persist session to storage
        if (sessionId != null) {
          html.window.sessionStorage[_sessionStorageKey] = sessionId;
        }
        
        return sessionId;
      }
    } catch (e) {
      print('❌ Session creation error: $e');
    }
    return null;
  }

  // File picker
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

  // Upload files with streaming response + user data
  static Stream<String> uploadFilesStream({
    required String question,
    List<WebFile>? files,
  }) async* {
    final user = currentUser; // Use the persistent getter
    
    String? sessionId = currentSessionId;
    if (sessionId == null) {
      sessionId = await _createSession();
      if (sessionId == null) {
        yield 'Sorry, our system is experiencing issues. Please try again later.';
        return;
      }
    }

    try {
      final dio = Dio();
      final formDataMap = {
        'question': question.trim().isEmpty ? 'Analyze this file' : question.trim(),
        'session_id': sessionId,
      };
      
      // Add user info to request if available
      if (user?.name != null) {
        formDataMap['name'] = user!.name!;
      }
      if (user?.username != null) {
        formDataMap['username'] = user!.username!;
      }
      if (user?.birthday != null) {
        formDataMap['birthday'] = user!.birthday!;
      }
      
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

      final response = await dio.post(
        '$baseUrl/lumir/chat/v1',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final answer = response.data['answer']?.toString() ?? 'Sorry, no response available';

        // Stream chunks
        final chunks = _splitText(answer);
        for (var chunk in chunks) {
          await Future.delayed(const Duration(milliseconds: 50));
          yield chunk;
        }
      } else {
        yield 'Sorry, our system is experiencing issues. Please try again later.';
      }
    } catch (e) {
      yield 'Sorry, our system is experiencing issues. Please try again later.';
    }
  }

  // Upload files without streaming
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
  static void clearSession() {
    _sessionId = null;
    html.window.sessionStorage.remove(_sessionStorageKey);
  }
  
  static void clearUserData() {
    _currentUserData = null;
    html.window.sessionStorage.remove(_userStorageKey);
  }
  
  static void clearAll() {
    clearSession();
    clearUserData();
  }
  
  static String formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static void dispose() {
    _userStreamController?.close();
  }
}