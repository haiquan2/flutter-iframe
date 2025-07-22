import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openai_stream/models/message.dart';

Widget actionButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    ),
  );
}

void copyToClipboardAndShowSnackBar(BuildContext context, Message text) {
  // Function to copy text to clipboard
  Clipboard.setData(ClipboardData(text: text.content));
  
  // Show a snackbar to confirm the action
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.check, color: Colors.green),
          SizedBox(width: 8),
          Text('Copied to clipboard!'),
        ],
      ),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: 20,
        left: MediaQuery.of(context).size.width - 220,
        right: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

void showToast({
  required BuildContext context,
  required String message,
  IconData icon = Icons.info,
  Color iconColor = Colors.blue,
  Duration duration = const Duration(seconds: 1),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Flexible(child: Text(message)),
        ],
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: 20,
        left: MediaQuery.of(context).size.width - 220,
        right: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

void feedbackResponse(bool isPositive, Message message) {
  // Solving feedback logic here
  // Positive feedback change color of icon to green
  // Negative feedback open a modal or dialog to ask for more details

  // can send this to your analytics or feedback system
  print(
      'Feedback: ${isPositive ? 'Positive' : 'Negative'} for message: ${message.content.substring(0, 50)}...');
}


/// Helper class for keyboard shortcuts text
class KeyboardShortcutHelper {
  static String getShortcutText() {
    // Use foundation.dart's defaultTargetPlatform which works on web
    if (kIsWeb) {
      return 'Press Shift+Enter for new line, Enter to send';
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'Press Cmd+Enter for new line, Enter to send';
      default:
        return 'Press Ctrl+Enter for new line, Enter to send';
    }
  }
}