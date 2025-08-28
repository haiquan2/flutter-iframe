// import 'package:flutter/material.dart';
// import 'dart:async';
// import '../../../services/chat_service.dart';
// import '../../../models/message.dart';

// class ChatController extends ChangeNotifier {
//   final List<Message> _messages = [];
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoading = false;
//   StreamSubscription? _currentStream;

//   List<Message> get messages => List.unmodifiable(_messages);
//   ScrollController get scrollController => _scrollController;
//   bool get isLoading => _isLoading;

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _currentStream?.cancel();
//     super.dispose();
//   }

//   Future<void> sendMessage(String text, {List<SimpleFile>? files}) async {
//     if (text.trim().isEmpty && (files == null || files.isEmpty)) return;
//     if (_isLoading) return;

//     // Add user message
//     _addMessage(Message(
//       text: text.trim(),
//       isUser: true,
//       timestamp: DateTime.now(),
//       files: files?.map((f) => f.name).toList(),
//     ));

//     // Add loading message
//     final loadingMessage = Message(
//       text: '',
//       isUser: false,
//       timestamp: DateTime.now(),
//       isLoading: true,
//       modelName: 'pythera',
//     );
//     _addMessage(loadingMessage);

//     _setLoading(true);
//     _scrollToBottom();

//     try {
//       String response = '';
//       _currentStream = ChatService.getChatResponse(
//         userMessage: text.trim(),
//         files: files,
//       ).listen(
//         (chunk) {
//           response += chunk;
//           _updateLastMessage(Message(
//             content: response.trim(),
//             isUser: false,
//             timestamp: DateTime.now(),
//             isLoading: false,
//             modelName: 'pythera',
//           ));
//           _scrollToBottom();
//         },
//         onError: (error) {
//           _handleError(error);
//         },
//         onDone: () {
//           _setLoading(false);
//           _scrollToBottom();
//         },
//       );
//     } catch (e) {
//       _handleError(e);
//     }
//   }

//   void stopResponse() {
//     _currentStream?.cancel();
//     _currentStream = null;

//     if (_messages.isNotEmpty && _messages.last.isLoading) {
//       final currentContent = _messages.last.content;
//       _updateLastMessage(Message(
//         content: currentContent.isEmpty ? 'Đã dừng.' : currentContent,
//         isUser: false,
//         timestamp: DateTime.now(),
//         isLoading: false,
//         modelName: 'pythera',
//       ));
//     }

//     _setLoading(false);
//   }

//   void clearMessages() {
//     _messages.clear();
//     notifyListeners();
//   }

//   void _addMessage(Message message) {
//     _messages.add(message);
//     notifyListeners();
//   }

//   void _updateLastMessage(Message message) {
//     if (_messages.isNotEmpty) {
//       _messages[_messages.length - 1] = message;
//       notifyListeners();
//     }
//   }

//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 100),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   void _handleError(dynamic error) {
//     _addMessage(Message(
//       content: 'Lỗi: $error',
//       isUser: false,
//       timestamp: DateTime.now(),
//       isLoading: false,
//       modelName: 'pythera',
//     ));
//     _setLoading(false);
//   }
// }