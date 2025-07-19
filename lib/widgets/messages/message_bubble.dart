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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: message.isUser
                  ? theme.colorScheme.primary
                  : (isDark
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF6366F1)),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              message.isUser ? Icons.person : Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message Container
                MessageContent(message: message),

                // Action Buttons (for AI messages)
                MessageActions(message: message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
