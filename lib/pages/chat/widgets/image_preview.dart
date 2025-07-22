// widgets/chat/image_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for displaying image preview in chat input - Grok style
class ImagePreview extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onClear;

  const ImagePreview({
    super.key,
    required this.imageBytes,
    required this.onClear,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                widget.imageBytes,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            // Remove button show when hovering 
            if (_isHovering)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                    onPressed: widget.onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}