import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/widgets/messages/message_actions.dart';
import 'package:flutter_openai_stream/widgets/messages/message_content.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: message.isUser ? _buildUserMessage(isDark) : _buildBotMessage(isDark),
    );
  }

  Widget _buildUserMessage(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 280, 
            ),
            child: MessageContent(message: message),
          ),
        ),
      ],
    );
  }

  Widget _buildBotMessage(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'lib/images/icon-chatbot.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.auto_awesome,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  size: 18,
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MessageContent(message: message),
              MessageActions(message: message),
            ],
          ),
        ),
      ],
    );
  }
}
