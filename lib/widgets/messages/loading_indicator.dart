import 'package:flutter/material.dart';

Widget buildLoadingIndicator() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey[600]!,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'AI is thinking...',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );
}
