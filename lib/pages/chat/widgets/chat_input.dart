// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../../services/chat_service.dart';

// enum ChatInputMode { chat }
// enum ChatInputStyle { modern }

// class ChatInput extends StatefulWidget {
//   final Function(String message, {List<WebFile>? files}) onSubmit;
//   final Function()? onStop;
//   final String placeholder;
//   final bool disabled;
//   final bool isLoading;
//   final ChatInputMode mode;
//   final ChatInputStyle style;

//   const ChatInput({
//     super.key,
//     required this.onSubmit,
//     this.onStop,
//     this.placeholder = 'Type a message...',
//     this.disabled = false,
//     this.isLoading = false,
//     this.mode = ChatInputMode.chat,
//     this.style = ChatInputStyle.modern,
//   });

//   @override
//   State<ChatInput> createState() => _ChatInputState();
// }

// class _ChatInputState extends State<ChatInput> {
//   final TextEditingController _textController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   List<WebFile> _selectedFiles = [];
//   bool _isPickingFiles = false;

//   @override
//   void dispose() {
//     _textController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFiles() async {
//     if (_isPickingFiles) return;

//     setState(() => _isPickingFiles = true);

//     try {
//       print('Starting file selection...');

//       final selectedFiles = await ChatService.pickFiles();

//       if (selectedFiles != null && selectedFiles.isNotEmpty) {
//         setState(() {
//           _selectedFiles.addAll(selectedFiles);
//         });

//         print('Successfully selected ${selectedFiles.length} files:');
//         for (var file in selectedFiles) {
//           print('  - ${file.name} (${file.size} bytes)');
//         }

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Đã chọn ${selectedFiles.length} file'),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 2),
//             ),
//           );
//         }
//       } else {
//         print('No files selected');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Không có file nào được chọn'),
//               backgroundColor: Colors.orange,
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print('Error in file selection: $e');

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Lỗi khi chọn file: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       setState(() => _isPickingFiles = false);
//     }
//   }

//   void _removeFile(int index) {
//     setState(() {
//       _selectedFiles.removeAt(index);
//     });
//   }

//   void _submitMessage() {
//     final message = _textController.text.trim();
//     if (message.isEmpty && _selectedFiles.isEmpty) return;

//     print(
//         'ChatInput: Submitting message text="$message", files=${_selectedFiles.map((f) => f.name).toList()}');

//     widget.onSubmit(
//       message.isEmpty ? 'Phân tích file này' : message,
//       files: _selectedFiles.isEmpty ? null : _selectedFiles,
//     );

//     _textController.clear();
//     setState(() {
//       _selectedFiles.clear();
//     });
//   }

//   void _handleKeyPress(RawKeyEvent event) {
//     if (event.isKeyPressed(LogicalKeyboardKey.enter) &&
//         !event.isShiftPressed &&
//         !widget.disabled &&
//         !widget.isLoading) {
//       _submitMessage();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         border: Border(
//           top: BorderSide(
//             color: colorScheme.outline.withOpacity(0.2),
//             width: 1,
//           ),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // File preview area
//           if (_selectedFiles.isNotEmpty)
//             Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               child: Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: _selectedFiles.asMap().entries.map((entry) {
//                   final index = entry.key;
//                   final file = entry.value;
//                   return Chip(
//                     label: Text(
//                       '${file.name} (${ChatService.formatFileSize(file.size)})',
//                       style: TextStyle(
//                         color: colorScheme.onSecondaryContainer,
//                         fontSize: 12,
//                       ),
//                     ),
//                     backgroundColor: colorScheme.secondaryContainer,
//                     deleteIcon: Icon(
//                       Icons.close,
//                       size: 16,
//                       color: colorScheme.onSecondaryContainer,
//                     ),
//                     onDeleted: () => _removeFile(index),
//                   );
//                 }).toList(),
//               ),
//             ),

//           // Input area
//           Row(
//             children: [
//               // File picker button
//               IconButton(
//                 onPressed:
//                     widget.disabled || widget.isLoading || _isPickingFiles
//                         ? null
//                         : _pickFiles,
//                 icon: _isPickingFiles
//                     ? SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: colorScheme.primary,
//                         ),
//                       )
//                     : Icon(
//                         Icons.attach_file,
//                         color: widget.disabled || widget.isLoading
//                             ? colorScheme.onSurface.withOpacity(0.4)
//                             : colorScheme.primary,
//                       ),
//                 tooltip:
//                     _isPickingFiles ? 'Đang chọn file...' : 'Đính kèm file',
//               ),

//               // Text input
//               Expanded(
//                 child: RawKeyboardListener(
//                   focusNode: _focusNode,
//                   onKey: _handleKeyPress,
//                   child: TextField(
//                     controller: _textController,
//                     enabled: !widget.disabled && !widget.isLoading,
//                     maxLines: 5,
//                     minLines: 1,
//                     decoration: InputDecoration(
//                       hintText: _selectedFiles.isNotEmpty
//                           ? 'Hỏi gì về file này? (không bắt buộc)'
//                           : widget.placeholder,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                         borderSide: BorderSide(
//                           color: colorScheme.outline.withOpacity(0.3),
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                         borderSide: BorderSide(
//                           color: colorScheme.outline.withOpacity(0.3),
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                         borderSide: BorderSide(
//                           color: colorScheme.primary,
//                           width: 2,
//                         ),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       filled: true,
//                       fillColor: colorScheme.surface,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 8),

//               // Send/Stop button
//               IconButton(
//                 onPressed: widget.disabled
//                     ? null
//                     : widget.isLoading
//                         ? widget.onStop
//                         : _submitMessage,
//                 icon: Icon(
//                   widget.isLoading ? Icons.stop : Icons.send,
//                   color: widget.disabled
//                       ? colorScheme.onSurface.withOpacity(0.4)
//                       : colorScheme.primary,
//                 ),
//                 tooltip: widget.isLoading ? 'Dừng' : 'Gửi',
//               ),
//             ],
//           ),

//           // File type hint and status
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     _selectedFiles.isEmpty
//                         ? 'Supported: PDF, DOCX, TXT, CSV'
//                         : '${_selectedFiles.length} file(s) selected',
//                     style: TextStyle(
//                       color: colorScheme.onSurface.withOpacity(0.6),
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 if (_selectedFiles.isNotEmpty)
//                   Text(
//                     'Max: 10 files, 50MB each',
//                     style: TextStyle(
//                       color: colorScheme.onSurface.withOpacity(0.5),
//                       fontSize: 10,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
