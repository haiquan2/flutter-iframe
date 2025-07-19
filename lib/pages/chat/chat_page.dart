import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/utils/scroll.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_empty.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_header.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_input.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/messages_list.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/sidebar.dart';
import '../../services/chat_service.dart';
import '../../models/message.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();

    // Get initial message from router extra if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is String && extra.isNotEmpty) {
        _handleMessageSubmit(extra);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMessageSubmit(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(Message(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
      _isLoading = true;
    });

    scrollToBottom(_scrollController);

    try {
      String response = '';
      await for (String chunk in ChatService.getChatResponse(message)) {
        setState(() {
          response += chunk;
          _messages[_messages.length - 1] = Message(
            content: response.trim(),
            isUser: false,
            timestamp: DateTime.now(),
            isLoading: false,
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1] = Message(
          content: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideBar(
            isCollapsed: _isSidebarCollapsed,
            onToggle: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                // Chat Header
                ChatHeader(chatId: widget.chatId),

                // Messages Area
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          // Messages Area
                          Expanded(
                            child: _messages.isEmpty
                                ? const ChatEmptyState()
                                : MessagesList(
                                    messages: _messages,
                                    scrollController: _scrollController,
                                  ),
                          ),

                          // Input Area
                          ChatInputBox(
                            onMessageSubmit: _handleMessageSubmit,
                            disabled: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
