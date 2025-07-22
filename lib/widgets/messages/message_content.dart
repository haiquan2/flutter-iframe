import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/core/utils/text_formatter.dart';
import 'package:flutter_openai_stream/models/message.dart';
import 'package:flutter_openai_stream/widgets/messages/loading_indicator.dart';
import 'dart:html' as html;

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
                // Show Image preview first if available
                if (message.imageBytes != null) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildImagePreviewList(context, isDark),
                  ),
                // Show user request below images
                if (message.content.isNotEmpty)
                  formattedMessage(context, isDark, message),
              ],
            ),
    );
  }

  Widget _buildImagePreviewList(BuildContext context, bool isDark) {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 1,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 0 ? 8.0 : 0),
            child: _buildImageThumbnail(context, isDark),
          );
        },
      ),
    );
  }

  Widget _buildImageThumbnail(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showImageInParent(),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              Image.memory(
                message.imageBytes!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageInParent() {
    // Convert image bytes to base64
    final base64Image = html.window.btoa(String.fromCharCodes(message.imageBytes!));
    // Post message to parent window
    html.window.parent?.postMessage({
      'type': 'showImage',
      'imageSrc': 'data:image/jpeg;base64,$base64Image',
    }, '*');
  }
}