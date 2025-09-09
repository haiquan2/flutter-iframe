import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/theme/colors.dart';
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
      // User: width tự động, Bot: full width
      width: message.isUser ? null : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isUser
            ? AppColors.primaryLumir
            : AppColors.boxLumir,
        borderRadius: message.isUser 
          ? BorderRadius.circular(20)
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
        border: message.isUser 
          ? null 
          : Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: message.isLoading
          ? buildLoadingIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: message.isUser ? MainAxisSize.min : MainAxisSize.max,
              children: [
                if (message.files != null && message.files!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildFileList(context, isDark, message.files!),
                  ),
                if (message.text.isNotEmpty)
                  _buildMessageText(context, isDark),
              ],
            ),
    );
  }

  Widget _buildMessageText(BuildContext context, bool isDark) {
    if (message.isUser) {
      return SelectableText(
        message.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      );
    } else {
      return formattedMessage(context, isDark, message);
    }
  }

  Widget _buildFileList(BuildContext context, bool isDark, List<String> filePaths) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: message.isUser, 
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
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: message.isUser 
          ? Colors.white.withOpacity(0.15)
          : (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isUser 
            ? Colors.white.withOpacity(0.3)
            : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(fileName),
            size: 16,
            color: message.isUser 
              ? Colors.white
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            fileName.length > 6 ? '${fileName.substring(0, 4)}...' : fileName,
            style: TextStyle(
              fontSize: 7,
              color: message.isUser 
                ? Colors.white.withOpacity(0.9)
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'txt': return Icons.text_snippet;
      case 'csv': case 'xlsx': case 'xls': return Icons.table_chart;
      case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }
}
