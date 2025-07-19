import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openai_stream/core/constants/app_sizes.dart';
import 'package:flutter_openai_stream/core/utils/helper.dart';

class ChatBox extends StatefulWidget {
  final Function(String) onSubmit;
  final Function()? onAttachFile;
  final String placeholder;
  final bool disabled;
  final double maxHeight;

  const ChatBox({
    super.key,
    required this.onSubmit,
    this.onAttachFile,
    this.placeholder = 'Type your message here...',
    this.disabled = false,
    this.maxHeight = AppSizes.kChatBoxMaxHeight,
  });

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.disabled) {
      widget.onSubmit(text);
      _controller.clear();
      setState(() {});
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // ignore: deprecated_member_use
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
              minHeight: 56.0,
              maxHeight: widget.maxHeight,
            ),
            // ignore: deprecated_member_use
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              // ignore: deprecated_member_use
              onKey: (RawKeyEvent event) {
                // ignore: deprecated_member_use
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    // ignore: deprecated_member_use
                    !event.isShiftPressed) {
                  _handleSubmit();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.disabled,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Action
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: widget.disabled
                      ? null
                      : () => showToast(
                            context: context,
                            message: "No support yet!",
                            icon: Icons.info_outline,
                            iconColor: Colors.orange,
                          ),
                  icon: Icon(
                    Icons.attach_file,
                    size: 22,
                    color: widget.disabled
                        ? Colors.grey
                        : (isDark ? Colors.grey[300] : Colors.grey[600]),
                  ),
                  tooltip: 'Attach file',
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.disabled
                        ? Colors.grey[300]
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: widget.disabled ? null : _handleSubmit,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: widget.disabled ? Colors.grey[600] : Colors.white,
                    ),
                    tooltip: 'Send message',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
