import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../models/message.dart';
import 'widgets/messages_list.dart';
import 'package:web/web.dart' as web;
import 'dart:typed_data';

class ChatPage extends StatefulWidget {
  final String? chatId;
  
  const ChatPage({super.key, this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<WebFile> _files = [];
  List<Message> _messages = [];
  bool _isUploading = false;
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<String>? _streamSubscription;
  final FocusNode _inputFocusNode = FocusNode();
  bool _isTyping = false;

  // Lấy chatId từ widget hoặc URL
  String get _currentChatId {
    if (widget.chatId != null) return widget.chatId!;
    
    final queryParams = Uri.parse(web.window.location.href).queryParameters;
    return queryParams['chatId'] ?? 'default';
  }

  // Kiểm tra xem có phải iframe mode không
  bool get _isIframeMode {
    final queryParams = Uri.parse(web.window.location.href).queryParameters;
    return queryParams['iframe'] == 'true';
  }

  // Lấy theme từ URL parameters
  String get _urlTheme {
    final queryParams = Uri.parse(web.window.location.href).queryParameters;
    return queryParams['theme'] ?? 'light';
  }

  @override
  void initState() {
    super.initState();
    print('ChatPage initialized with chatId: ${_currentChatId}');
    
    // Thông báo iframe đã sẵn sàng
    if (_isIframeMode) {
      _notifyParentReady();
    }

    // Listen for focus changes
    _inputFocusNode.addListener(() {
      setState(() {
        _isTyping = _inputFocusNode.hasFocus;
      });
    });
  }

  void _notifyParentReady() {
    web.window.parent?.postMessage({
      'type': 'iframe_ready',
      'chatId': _currentChatId,
    }.toString() as JSAny?, '*' as JSAny);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _questionController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String _generateMessageId() {
    return (web.window.crypto as dynamic)
        .getRandomValues(Uint8List(8))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pickFiles() async {
    if (_isUploading) return;
    
    final files = await ChatService.pickFiles();
    if (files != null) {
      setState(() {
        _files = files;
      });
      
      if (mounted) {
        _showSnackBar('Đã chọn ${files.length} file(s)', isSuccess: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    if (!_isIframeMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : Colors.orange),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Cho iframe mode, hiển thị toast nhỏ gọn hơn
      _showCompactToast(message, isSuccess: isSuccess, isError: isError);
    }
  }

  void _showCompactToast(String message, {bool isSuccess = false, bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isError 
                ? Colors.red.shade600 
                : (isSuccess ? Colors.green.shade600 : Colors.orange.shade600),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _sendMessage() async {
    final messageText = _questionController.text.trim();
    if (messageText.isEmpty && _files.isEmpty) {
      _showSnackBar('Vui lòng nhập tin nhắn hoặc chọn file');
      return;
    }

    final finalMessage = messageText.isEmpty ? 'Phân tích file này' : messageText;

    setState(() {
      _isUploading = true;
      
      // Add user message
      _messages.add(Message(
        id: _generateMessageId(),
        text: finalMessage,
        isUser: true,
        timestamp: DateTime.now(),
        files: _files.map((f) => f.name).toList(),
      ));

      // Add loading bot message
      _messages.add(Message(
        id: _generateMessageId(),
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    _questionController.clear();
    final selectedFiles = List<WebFile>.from(_files);
    setState(() {
      _files.clear();
    });
    
    _scrollToBottom();

    try {
      String fullResponse = '';
      final botMessageIndex = _messages.length - 1;

      _streamSubscription = ChatService.uploadFilesStream(
        question: finalMessage,
        files: selectedFiles.isEmpty ? null : selectedFiles,
      ).listen(
        (chunk) {
          fullResponse += chunk;
          if (mounted) {
            setState(() {
              _messages[botMessageIndex] = _messages[botMessageIndex].copyWith(
                text: fullResponse,
                isLoading: false,
              );
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          print('Streaming error: $error');
          if (mounted) {
            setState(() {
              _messages[botMessageIndex] = _messages[botMessageIndex].copyWith(
                text: 'Có lỗi xảy ra: $error',
                isLoading: false,
              );
              _isUploading = false;
            });
            _showSnackBar('Có lỗi xảy ra', isError: true);
          }
        },
        onDone: () {
          print('Streaming completed');
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error in sendMessage: $e');
      if (mounted) {
        setState(() {
          final botMessageIndex = _messages.length - 1;
          _messages[botMessageIndex] = _messages[botMessageIndex].copyWith(
            text: 'Có lỗi xảy ra: $e',
            isLoading: false,
          );
          _isUploading = false;
        });
        _showSnackBar('Có lỗi xảy ra', isError: true);
      }
    }
  }

  void _stopStreaming() {
    _streamSubscription?.cancel();
    setState(() {
      _isUploading = false;
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = _messages[lastIndex].copyWith(
          text: _messages[lastIndex].text.isEmpty 
            ? 'Đã dừng phản hồi' 
            : _messages[lastIndex].text,
          isLoading: false,
        );
      }
    });
  }

  void _clearAll() {
    _streamSubscription?.cancel();
    setState(() {
      _files.clear();
      _messages.clear();
      _isUploading = false;
    });
    _questionController.clear();
    ChatService.clearSession();
    _showSnackBar('Đã xóa cuộc trò chuyện', isSuccess: true);
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _urlTheme == 'dark' || 
                       Theme.of(context).brightness == Brightness.dark;
    
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: _isIframeMode 
          ? (isDarkMode ? const Color(0xFF1a1a1a) : Colors.white)
          : null,
        appBar: _isIframeMode ? _buildCompactAppBar(isDarkMode) : _buildNormalAppBar(),
        body: Column(
          children: [
            // Messages Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _messages.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : MessagesList(
                        messages: _messages,
                        scrollController: _scrollController,
                      ),
              ),
            ),
            
            // File Preview Area
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _files.isEmpty ? 0 : null,
              child: _files.isNotEmpty ? _buildFilePreview(isDarkMode) : null,
            ),
            
            // Input Area
            _buildInputArea(isDarkMode),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildCompactAppBar(bool isDarkMode) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(45),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2a2a2a) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (_messages.isNotEmpty)
                  IconButton(
                    onPressed: _clearAll,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                    tooltip: 'Xóa chat',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar? _buildNormalAppBar() {
    return AppBar(
      title: Text(_currentChatId != 'default' 
        ? 'Chat (${_currentChatId.length > 8 ? _currentChatId.substring(0, 8) : _currentChatId})'
        : 'AI Chat'
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      actions: [
        IconButton(
          onPressed: _clearAll,
          icon: const Icon(Icons.refresh),
          tooltip: 'Clear Chat',
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _isIframeMode ? 60 : 80,
              height: _isIframeMode ? 60 : 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400.withOpacity(0.8),
                    Colors.purple.shade400.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: _isIframeMode ? 30 : 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Xin chào! Tôi có thể giúp gì cho bạn?',
              style: TextStyle(
                fontSize: _isIframeMode ? 15 : 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hỏi bất cứ điều gì hoặc tải file lên để phân tích',
              style: TextStyle(
                fontSize: _isIframeMode ? 12 : 14,
                color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isIframeMode) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickAction('📝 Viết nội dung', isDarkMode),
                  _buildQuickAction('💡 Ý tưởng', isDarkMode),
                  _buildQuickAction('🔍 Phân tích', isDarkMode),
                  _buildQuickAction('❓ Hỏi đáp', isDarkMode),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, bool isDarkMode) {
    return InkWell(
      onTap: () {
        _questionController.text = label.substring(2);
        _inputFocusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode 
            ? Colors.white.withOpacity(0.1) 
            : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode 
              ? Colors.white.withOpacity(0.2) 
              : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.all(_isIframeMode ? 6 : 16).copyWith(bottom: 0),
      padding: EdgeInsets.all(_isIframeMode ? 8 : 12),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_isIframeMode ? 8 : 12),
        border: Border.all(
          color: isDarkMode 
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 14,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Files (${_files.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: _isIframeMode ? 11 : 14,
                  color: isDarkMode ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _files.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileIcon(file.name),
                      size: 12,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      file.name.length > 15 
                        ? '${file.name.substring(0, 12)}...'
                        : file.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeFile(index),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2a2a2a) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.all(_isIframeMode ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // File attach button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isUploading ? null : _pickFiles,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: _isIframeMode ? 32 : 40,
                    height: _isIframeMode ? 32 : 40,
                    decoration: BoxDecoration(
                      color: _files.isNotEmpty 
                        ? Colors.blue.withOpacity(0.1)
                        : (isDarkMode 
                            ? Colors.white.withOpacity(0.05) 
                            : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.attach_file,
                      size: _isIframeMode ? 18 : 20,
                      color: _files.isNotEmpty 
                        ? Colors.blue.shade600
                        : (isDarkMode ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Text input
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: _isIframeMode ? 80 : 120,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isTyping
                        ? Colors.blue.shade400.withOpacity(0.5)
                        : (isDarkMode 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200),
                      width: _isTyping ? 1.5 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _questionController,
                    focusNode: _inputFocusNode,
                    enabled: !_isUploading,
                    maxLines: null,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: _isIframeMode ? 13 : 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: _files.isNotEmpty 
                        ? 'Hỏi về files này...'
                        : 'Nhập tin nhắn...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                        fontSize: _isIframeMode ? 13 : 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _isIframeMode ? 12 : 16,
                        vertical: _isIframeMode ? 8 : 10,
                      ),
                    ),
                    onSubmitted: (_) => _isUploading ? null : _sendMessage(),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send/Stop button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isUploading ? _stopStreaming : _sendMessage,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: _isIframeMode ? 32 : 40,
                    height: _isIframeMode ? 32 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isUploading 
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_isUploading ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isUploading ? Icons.stop : Icons.send_rounded,
                      color: Colors.white,
                      size: _isIframeMode ? 16 : 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'csv':
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}