import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/utils/helper.dart';
import 'package:flutter_openai_stream/models/message.dart';

class MessageActions extends StatelessWidget {
  final Message message;
  const MessageActions({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser || message.isLoading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          actionButton(
            icon: Icons.content_copy,
            tooltip: 'Copy',
            onPressed: () => copyToClipboardAndShowSnackBar(context, message),
          ),
          const SizedBox(width: 8),
          actionButton(
            icon: Icons.thumb_up_outlined,
            tooltip: 'Good response',
            onPressed: () => feedbackResponse(true, message),
          ),
          const SizedBox(width: 8),
          actionButton(
            icon: Icons.thumb_down_outlined,
            tooltip: 'Poor response',
            onPressed: () => feedbackResponse(false, message),
          ),
        ],
      ),
    );
  }
}
