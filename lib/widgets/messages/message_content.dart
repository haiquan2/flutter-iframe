import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/utils/text_formatter.dart';
import 'package:flutter_openai_stream/models/message.dart';
import 'package:flutter_openai_stream/widgets/messages/loading_indicator.dart';

class MessageContent extends StatelessWidget {
  final Message message;

  const MessageContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isUser
            ? (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6))
            : (isDark ? const Color(0xFF1F2937) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: message.isLoading
          ? buildLoadingIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show File list if available
                if (message.files != null && message.files!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildFileList(context, isDark, message.files!),
                  ),
                // Show user request below images
                if (message.text.isNotEmpty)
                  formattedMessage(context, isDark, message),
              ],
            ),
    );
  }

  Widget _buildFileList(BuildContext context, bool isDark, List<String> filePaths) {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filePaths.length,
        itemBuilder: (context, index) {
          final filePath = filePaths[index];
          final fileName = filePath.split('/').last;
          return Padding(
            padding: EdgeInsets.only(right: index < filePaths.length - 1 ? 8.0 : 0),
            child: _buildFileThumbnail(context, isDark, fileName),
          );
        },
      ),
    );
  }

  Widget _buildFileThumbnail(BuildContext context, bool isDark, String fileName) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 24, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            fileName.length > 10 ? '${fileName.substring(0, 10)}...' : fileName,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}