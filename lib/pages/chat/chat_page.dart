import 'dart:js_interop';
import 'dart:js_interop_unsafe';
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
  bool _scrollEnabled = true;
  web.EventListener? _wheelListener;
  web.EventListener? _touchListener;
  web.EventListener? _scrollListener;
  web.EventListener? _messageListener;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    
    if (widget.isIframe) {
      _setupIframeScrollHandling();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialMessage();
    });
  }

  void _setupIframeScrollHandling() {
    // Set up message listener for parent communication
    _messageListener = (web.Event event) {
      final messageEvent = event as web.MessageEvent;
      final data = messageEvent.data;
      
      if (data != null) {
        try {
          final message = data as JSObject;
          final type = message.getProperty('type'.toJS) as JSString?;
          
          if (type?.toDart == 'enable_scroll') {
            final enabled = message.getProperty('enabled'.toJS) as JSBoolean?;
            _scrollEnabled = enabled?.toDart ?? true;
            _updateScrollBehavior();
          } else if (type?.toDart == 'wheel_event') {
            final deltaY = message.getProperty('deltaY'.toJS) as JSNumber?;
            if (deltaY != null && _scrollEnabled) {
              _handleWheelEvent(deltaY.toDartDouble);
            }
          }
        } catch (e) {
          print('Error handling message: $e');
        }
      }
    } as web.EventListener?;
    
    web.window.addEventListener('message', _messageListener!);
    
    // Initial setup
    _updateScrollBehavior();
    _setupEventListeners();
    
    // Notify parent that iframe is ready
    _notifyParentReady();
  }

  void _setupEventListeners() {
    // Handle wheel events
    _wheelListener = (web.Event event) {
      if (!_scrollEnabled) {
        event.preventDefault();
        event.stopPropagation();
      }
    } as web.EventListener?;

    // Handle touch events
    _touchListener = (web.Event event) {
      if (!_scrollEnabled) {
        event.preventDefault();
        event.stopPropagation();
      }
    } as web.EventListener?;

    // Handle scroll events
    _scrollListener = (web.Event event) {
      if (!_scrollEnabled) {
        event.stopPropagation();
      }
    } as web.EventListener?;

    web.document.addEventListener('wheel', _wheelListener!, {
      'passive': false,
      'capture': true,
    } as JSAny);

    web.document.addEventListener('touchmove', _touchListener!, {
      'passive': false,
      'capture': true,
    } as JSAny);

    web.document.addEventListener('scroll', _scrollListener!, {
      'capture': true,
    } as JSAny);
  }

  void _updateScrollBehavior() {
    final style = web.document.getElementById('iframe-scroll-style') as web.HTMLStyleElement?;
    
    if (style != null) {
      style.remove();
    }

    final newStyle = web.document.createElement('style') as web.HTMLStyleElement;
    newStyle.id = 'iframe-scroll-style';
    
    if (_scrollEnabled) {
      newStyle.textContent = '''
        body {
          overflow: auto !important;
          position: relative !important;
          width: 100% !important;
          height: 100vh !important;
        }
        html {
          overflow: auto !important;
          height: 100% !important;
        }
        * {
          scrollbar-width: thin;
          scrollbar-color: rgba(0,0,0,0.3) transparent;
        }
        *::-webkit-scrollbar {
          width: 6px;
        }
        *::-webkit-scrollbar-track {
          background: transparent;
        }
        *::-webkit-scrollbar-thumb {
          background-color: rgba(0,0,0,0.3);
          border-radius: 3px;
        }
        *::-webkit-scrollbar-thumb:hover {
          background-color: rgba(0,0,0,0.5);
        }
      ''';
    } else {
      newStyle.textContent = '''
        body {
          overflow: hidden !important;
          position: fixed !important;
          width: 100% !important;
          height: 100vh !important;
        }
        html {
          overflow: hidden !important;
        }
      ''';
    }
    
    web.document.head!.appendChild(newStyle);
  }

  void _handleWheelEvent(double deltaY) {
    // Handle the wheel event within the Flutter app
    // This can be used to manually scroll specific widgets if needed
    if (_chatController.scrollController.hasClients) {
      final currentPosition = _chatController.scrollController.position.pixels;
      final maxScroll = _chatController.scrollController.position.maxScrollExtent;
      final minScroll = _chatController.scrollController.position.minScrollExtent;
      
      double newPosition = currentPosition + deltaY;
      newPosition = newPosition.clamp(minScroll, maxScroll);
      
      _chatController.scrollController.jumpTo(newPosition);
    }
  }

  void _notifyParentReady() {
    if (web.window.parent != web.window) {
      web.window.parent?.postMessage({
        'type': 'iframe_ready',
        'chatId': widget.chatId,
      } as JSAny?, '*' as JSAny);
    }
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
    // Clean up event listeners
    if (_wheelListener != null) {
      web.document.removeEventListener('wheel', _wheelListener!);
    }
    if (_touchListener != null) {
      web.document.removeEventListener('touchmove', _touchListener!);
    }
    if (_scrollListener != null) {
      web.document.removeEventListener('scroll', _scrollListener!);
    }
    if (_messageListener != null) {
      web.window.removeEventListener('message', _messageListener!);
    }
    
    // Remove style element
    final style = web.document.getElementById('iframe-scroll-style');
    style?.remove();
    
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