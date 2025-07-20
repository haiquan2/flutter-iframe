import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/utils/scroll.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_empty.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_header.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_input.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/messages_list.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat_service.dart';
import '../../models/message.dart';
import 'package:web/web.dart' as web;

class ChatPage extends StatefulWidget {
  final String chatId;
  final bool isIframe;

  const ChatPage({super.key, required this.chatId, this.isIframe = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
      body: widget.isIframe
          ? _buildCompactLayout() // Iframe mode: no sidebar
          : Row(
              children: [
                // Sidebar for web/mobile (non-iframe)
                Container(
                  width: 250,
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'AI Chat',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Chat History'),
                        onTap: () => context.go('/'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('New Chat'),
                        onTap: () => context.go('/chat/${generateChatId()}'),
                      ),
                      const Spacer(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          // Add settings navigation or action
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildChatLayout()),
              ],
            ),
    );
  }

  Widget _buildChatLayout() {
    return Column(
      children: [
        ChatHeader(chatId: widget.chatId),
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const ChatEmptyState()
                        : MessagesList(
                            messages: _messages,
                            scrollController: _scrollController,
                          ),
                  ),
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
    );
  }

  Widget _buildCompactLayout() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 400, maxHeight: 600),
                color: Theme.of(context).colorScheme.surface, // Đảm bảo màu nền
                child: Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? const ChatEmptyState()
                          : MessagesList(
                              messages: _messages,
                              scrollController: _scrollController,
                            ),
                    ),
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
    );
  }

  String generateChatId() {
    return (web.window.crypto as dynamic)
        .getRandomValues(Uint8List(8))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
