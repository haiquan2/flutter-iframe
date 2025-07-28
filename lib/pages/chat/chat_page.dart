import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_empty.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_header.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/chat_input.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/messages_list.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;
import 'controllers/chat_controller.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final bool isIframe;

  const ChatPage({super.key, required this.chatId, this.isIframe = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialMessage();
    });
  }

  void _handleInitialMessage() {
    final extra = GoRouterState.of(context).extra;
    if (extra != null) {
      if (extra is String && extra.isNotEmpty) {
        _chatController.sendMessage(extra);
      } else if (extra is Map<String, dynamic>) {
        final text = extra['text'] as String? ?? '';
        final imageBytes = extra['imageBytes'] as Uint8List?;
        if (text.isNotEmpty || imageBytes != null) {
          _chatController.sendMessage(text, imageBytes: imageBytes);
        }
      }
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleMessageSubmit(String message, {Uint8List? imageBytes}) {
    _chatController.sendMessage(message, imageBytes: imageBytes);
  }

  void _handleStop() {
    _chatController.stopResponse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.isIframe
          ? _buildCompactLayout()
          : Row(
              children: [
                // Sidebar for non-iframe mode
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
                    child: AnimatedBuilder(
                      animation: _chatController,
                      builder: (context, child) {
                        return _chatController.messages.isEmpty
                            ? const ChatEmptyState()
                            : MessagesList(
                                messages: _chatController.messages,
                                scrollController: _chatController.scrollController,
                              );
                      },
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _chatController,
                    builder: (context, child) {
                      return ChatInput(
                        onSubmit: _handleMessageSubmit,
                        onStop: _handleStop,
                        placeholder: 'Type a message...',
                        disabled: _chatController.isLoading,
                        isLoading: _chatController.isLoading,
                        mode: ChatInputMode.chat,
                        style: ChatInputStyle.modern,
                      );
                    },
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
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _chatController,
                        builder: (context, child) {
                          return _chatController.messages.isEmpty
                              ? const ChatEmptyState()
                              : MessagesList(
                                  messages: _chatController.messages,
                                  scrollController:
                                      _chatController.scrollController,
                                );
                        },
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _chatController,
                      builder: (context, child) {
                        return ChatInput(
                          onSubmit: _handleMessageSubmit,
                          onStop: _handleStop,
                          placeholder: 'Type a message...',
                          disabled: _chatController.isLoading,
                          isLoading: _chatController.isLoading,
                          mode: ChatInputMode.chat,
                          style: ChatInputStyle.modern,
                        );
                      },
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