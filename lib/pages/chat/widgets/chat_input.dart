// widgets/common/unified_chat_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openai_stream/core/constants/app_sizes.dart';
import 'package:flutter_openai_stream/core/utils/helper.dart';
import 'package:flutter_openai_stream/pages/chat/handler/image_handler.dart';
import 'package:flutter_openai_stream/pages/chat/widgets/image_preview.dart';

/// Unified chat input widget that can be used in both HomePage and ChatPage
/// with different behaviors based on the mode
class ChatInput extends StatefulWidget {
  // Core functionality
  final Function(String text, {Uint8List? imageBytes}) onSubmit;
  final Function()? onStop;
  
  // UI Configuration
  final String placeholder;
  final bool disabled;
  final bool isLoading;
  final double? maxHeight;
  
  // Mode-specific behavior
  final ChatInputMode mode;
  
  // Style variants
  final ChatInputStyle style;

  const ChatInput({
    super.key,
    required this.onSubmit,
    this.onStop,
    this.placeholder = 'Type your message here...',
    this.disabled = false,
    this.isLoading = false,
    this.maxHeight,
    this.mode = ChatInputMode.homepage,
    this.style = ChatInputStyle.modern,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImageHandler _imageHandler = ImageHandler();

  Uint8List? _selectedImage;
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    if (widget.disabled || widget.isLoading) return;

    widget.onSubmit(text, imageBytes: _selectedImage);
    _textController.clear();
    _clearImage();
    setState(() {
      _isComposing = false;
    });
    
    // Unfocus for homepage mode to prevent keyboard staying open
    if (widget.mode == ChatInputMode.homepage) {
      _focusNode.unfocus();
    }
  }

  void _handleStop() {
    if (widget.onStop != null) {
      widget.onStop!();
    }
  }

  Future<void> _handleImagePick() async {
    try {
      final imageBytes = await _imageHandler.pickImage();
      if (imageBytes != null) {
        setState(() {
          _selectedImage = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          message: 'Failed to pick image',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.style == ChatInputStyle.classic
        ? _buildClassicStyle()
        : _buildModernStyle();
  }

  Widget _buildClassicStyle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input area with keyboard listener
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _selectedImage != null ? 80.0 : 56.0,
              maxHeight: widget.maxHeight ?? AppSizes.kChatBoxMaxHeight,
            ),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !event.isShiftPressed) {
                  _handleSubmit();
                }
              },
              child: _buildTextInputArea(),
            ),
          ),

          // Action buttons
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildModernStyle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        widget.mode == ChatInputMode.chat ? 8 : 0,
        16,
        widget.mode == ChatInputMode.chat ? 16 : 0,
      ),
      decoration: BoxDecoration(
        color: widget.mode == ChatInputMode.chat 
            ? theme.scaffoldBackgroundColor 
            : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main input container
          _buildModernInputContainer(theme, isDark),
          
          // Helper text for chat mode
          if (widget.mode == ChatInputMode.chat && !widget.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                KeyboardShortcutHelper.getShortcutText(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernInputContainer(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNode.hasFocus
              ? theme.primaryColor.withOpacity(0.5)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Text input area (Row 1)
          _buildTextInputArea(),

          // Controls area (Row 2)
          _buildControlsArea(),
        ],
      ),
    );
  }

  Widget _buildTextInputArea() {
    final hasImage = _selectedImage != null;
    final isModern = widget.style == ChatInputStyle.modern;

    return Container(
      constraints: BoxConstraints(
        minHeight: hasImage ? 80 : (isModern ? 48 : 56),
        maxHeight: widget.maxHeight ?? (isModern ? 200 : AppSizes.kChatBoxMaxHeight),
      ),
      padding: EdgeInsets.fromLTRB(
        hasImage ? 8 : 16,
        isModern ? 12 : 16,
        16,
        isModern ? 8 : (hasImage ? 8 : 16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview (for modern style or when image is present)
          if (hasImage && isModern)
            ImagePreview(
              imageBytes: _selectedImage!,
              onClear: _clearImage,
            ),

          // Text input
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !event.isShiftPressed) {
                  _handleSubmit();
                }
              },
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: !widget.disabled && !widget.isLoading,
                maxLines: null,
                minLines: isModern ? null : 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  border: InputBorder.none,
                  contentPadding: isModern 
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                      : EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) {
                  if (!widget.disabled && !widget.isLoading) {
                    _handleSubmit();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Attachment button
          IconButton(
            onPressed: (widget.disabled || widget.isLoading) ? null : _handleImagePick,
            icon: Icon(
              Icons.attach_file,
              size: 22,
              color: (widget.disabled || widget.isLoading)
                  ? Colors.grey
                  : (isDark ? Colors.grey[300] : Colors.grey[600]),
            ),
            tooltip: 'Attach file',
          ),
          
          // Send button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getSendButtonColor(theme),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _getSendButtonAction(),
              padding: EdgeInsets.zero,
              icon: Icon(
                _getSendButtonIcon(),
                size: 16,
                color: (widget.disabled && !widget.isLoading) 
                    ? Colors.grey[600] 
                    : Colors.white,
              ),
              tooltip: widget.isLoading ? 'Stop' : 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Attachment button
          _buildAttachmentButton(),
          const Spacer(),
          // Send/Stop button
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (widget.disabled || widget.isLoading) ? null : _handleImagePick,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.attach_file_rounded,
            color: (widget.disabled || widget.isLoading)
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _isComposing || _selectedImage != null;
    final isActive = widget.isLoading || canSend;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: _getModernSendButtonColor(isActive),
        borderRadius: BorderRadius.circular(18),
        elevation: isActive ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.isLoading
              ? _handleStop
              : canSend
                  ? _handleSubmit
                  : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              widget.isLoading
                  ? Icons.stop_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Color _getSendButtonColor(ThemeData theme) {
    if (widget.isLoading) {
      return Colors.red.shade600;
    }
    
    if (widget.disabled) {
      return Colors.grey[300]!;
    }
    
    return theme.colorScheme.primary;
  }

  Color _getModernSendButtonColor(bool isActive) {
    if (widget.isLoading) {
      return Colors.red.shade600;
    }

    if (isActive) {
      return Theme.of(context).primaryColor;
    }

    return Colors.grey.shade400;
  }

  IconData _getSendButtonIcon() {
    return widget.isLoading ? Icons.stop_rounded : Icons.arrow_upward;
  }

  VoidCallback? _getSendButtonAction() {
    if (widget.isLoading) {
      return _handleStop;
    }
    
    if (widget.disabled) {
      return null;
    }
    
    final canSend = _isComposing || _selectedImage != null;
    return canSend ? _handleSubmit : null;
  }
}

// Enums for configuration
enum ChatInputMode {
  homepage,  // Used in HomePage - redirects after submit
  chat,      // Used in ChatPage - sends directly to controller
}

enum ChatInputStyle {
  classic,   // Original chat_box style
  modern,    // Modern chat input style (Grok/Claude inspired)
}

// Helper class for keyboard shortcuts
class KeyboardShortcutHelper {
  static String getShortcutText() {
    // You can customize this based on platform
    return 'Press Enter to send, Shift+Enter for new line';
  }
}