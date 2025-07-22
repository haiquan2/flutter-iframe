// pages/chat/controllers/chat_controller.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/services/chat_service.dart';
import '../../../models/message.dart';
import '../../../core/utils/scroll.dart';
import 'dart:async';

class ChatController extends ChangeNotifier {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String _selectedModel = 'gemini';
  StreamSubscription? _currentStream;

  // Getters
  List<Message> get messages => List.unmodifiable(_messages);
  ScrollController get scrollController => _scrollController;
  bool get isLoading => _isLoading;
  String get selectedModel => _selectedModel;

  @override
  void dispose() {
    _scrollController.dispose();
    _currentStream?.cancel();
    super.dispose();
  }

  // Change model
  void changeModel(String newModel) {
    if (_selectedModel != newModel) {
      _selectedModel = newModel;
      notifyListeners();
    }
  }

  // Send message with enhanced image support
  Future<void> sendMessage(String text, {Uint8List? imageBytes}) async {
    // Allow sending with just image (empty text) or just text
    if (text.trim().isEmpty && imageBytes == null) return;
    if (_isLoading) return;

    // Add user message - always add even if text is empty but image exists
    _addMessage(Message(
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
      modelName: _selectedModel,
    ));

    // Add loading message for AI response
    final loadingMessage = Message(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
      modelName: _selectedModel,
    );
    _addMessage(loadingMessage);

    _setLoading(true);

    // Scroll to bottom after adding messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom(_scrollController);
    });

    try {
      String response = '';

      // Create the stream for chat response
      _currentStream = ChatService.getChatResponse(
        userMessage: text.trim(),
        imageBytes: imageBytes,
      ).listen(
        (chunk) {
          response += chunk;
          // Update the last message (which should be our loading message)
          _updateLastMessage(Message(
            content: response.trim(),
            isUser: false,
            timestamp: DateTime.now(),
            isLoading: false,
            modelName: _selectedModel,
          ));

          // Auto-scroll to bottom during streaming
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onError: (error) {
          _handleError(error);
        },
        onDone: () {
          _setLoading(false);
          // Final scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom(_scrollController);
          });
        },
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // Stop current response
  void stopResponse() {
    _currentStream?.cancel();
    _currentStream = null;

    if (_messages.isNotEmpty && _messages.last.isLoading) {
      // If the last message is loading, update it appropriately
      final currentContent = _messages.last.content;
      _updateLastMessage(Message(
        content: currentContent.isEmpty
            ? 'Response stopped by user.'
            : currentContent,
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: false,
        modelName: _selectedModel,
      ));
    }

    _setLoading(false);
  }

  // Clear all messages (useful for new chat functionality)
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Add a message to the conversation
  void addMessage(Message message) {
    _addMessage(message);
  }

  // Get conversation history for context (useful for API calls)
  List<Map<String, dynamic>> getConversationHistory() {
    return _messages
        .where((message) => !message.isLoading)
        .map((message) => {
              'role': message.isUser ? 'user' : 'assistant',
              'content': message.content,
              'hasImage': message.imageBytes != null,
            })
        .toList();
  }

  // Private helper methods
  void _addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void _updateLastMessage(Message message) {
    if (_messages.isNotEmpty) {
      _messages[_messages.length - 1] = message;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    final errorMessage = 'An error occurred: $error';
    _addMessage(Message(
      content: errorMessage,
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: false,
      modelName: _selectedModel,
    ));
    _setLoading(false);
  }
}
