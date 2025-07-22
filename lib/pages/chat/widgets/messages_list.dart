import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/models/message.dart';
import 'package:flutter_openai_stream/widgets/messages/message_bubble.dart';

class MessagesList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;

  const MessagesList({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollStartNotification ||
            scrollNotification is ScrollUpdateNotification) {
          // Ngăn chặn sự kiện cuộn lan ra ngoài iframe
          return true;
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return MessageBubble(message: messages[index]);
        },
        physics: const ClampingScrollPhysics(), // Giới hạn cuộn trong vùng chat
      ),
    );
  }
}