import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/models/message.dart';

Widget formattedMessage(BuildContext context, bool isDark, Message message) {
  String cleanText = message.text;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _parseToWidgets(cleanText, isDark),
  );
}

List<Widget> _parseToWidgets(String text, bool isDark) {
  if (text.isEmpty) return [const SizedBox.shrink()];
  
  final List<Widget> widgets = [];
  
  // Split by \n to handle line breaks properly
  final lines = text.split('\n');
  
  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];
    
    if (line.isEmpty) {
      // Empty line = add spacing
      widgets.add(const SizedBox(height: 12));
      continue;
    }
    
    // Check for horizontal rule: --- or ___
    if (line.trim() == '---' || line.trim() == '___') {
      widgets.add(_createHorizontalRule(isDark));
      continue;
    }
    
    // Check for headers: # ## ### #### ##### ######
    final trimmedLine = line.trimLeft();
    if (trimmedLine.startsWith('#')) {
      final headerMatch = RegExp(r'^(#{1,6})\s+(.+)').firstMatch(trimmedLine);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final content = headerMatch.group(2)!;
        widgets.add(_createHeader(content, level, isDark));
        continue;
      }
    }
    
    // Check if line is bullet point: * text OR *   **text** (with spaces)
    if (trimmedLine.startsWith('* ') || trimmedLine.startsWith('*\t')) {
      // Bullet point: extract content after "* " or "*\t"
      String content;
      if (trimmedLine.startsWith('* ')) {
        content = trimmedLine.substring(2); // Remove "* "
      } else {
        content = trimmedLine.substring(2); // Remove "*\t"
      }
      
      if (content.trim().isNotEmpty) {
        widgets.add(_createBulletPoint(content, isDark));
      }
    } else {
      // Regular paragraph
      widgets.add(_createParagraph(line, isDark));
    }
  }
  
  return widgets.isEmpty ? [const SizedBox.shrink()] : widgets;
}

Widget _createHeader(String text, int level, bool isDark) {
  double fontSize;
  FontWeight fontWeight;
  
  switch (level) {
    case 1:
      fontSize = 20;
      fontWeight = FontWeight.bold;
      break;
    case 2:
      fontSize = 18;
      fontWeight = FontWeight.bold;
      break;
    case 3:
      fontSize = 16;
      fontWeight = FontWeight.w600;
      break;
    case 4:
      fontSize = 15;
      fontWeight = FontWeight.w600;
      break;
    case 5:
      fontSize = 14;
      fontWeight = FontWeight.w600;
      break;
    default:
      fontSize = 14;
      fontWeight = FontWeight.w500;
      break;
  }
  
  return Padding(
    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
    child: SelectableText.rich(
      TextSpan(children: _parseInlineFormatting(text.trim(), isDark)),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.3,
      ),
    ),
  );
}

Widget _createHorizontalRule(bool isDark) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 0.0), // Reduced vertical space
    child: Container(
      height: 0.2,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[600] : Colors.grey[300],
      ),
    ),
  );
}

Widget _createParagraph(String text, bool isDark) {
  if (text.trim().isEmpty) return const SizedBox(height: 12);
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: SelectableText.rich(
      TextSpan(children: _parseInlineFormatting(text.trim(), isDark)),
      style: TextStyle(
        color: isDark ? Colors.grey[100] : Colors.grey[800],
        fontSize: 14,
        height: 1.5,
      ),
    ),
  );
}

Widget _createBulletPoint(String text, bool isDark) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6.0, left: 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          margin: const EdgeInsets.only(top: 2),
          child: Text(
            '•',
            style: TextStyle(
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: SelectableText.rich(
            TextSpan(children: _parseInlineFormatting(text.trim(), isDark)),
            style: TextStyle(
              color: isDark ? Colors.grey[100] : Colors.grey[800],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

List<InlineSpan> _parseInlineFormatting(String line, bool isDark) {
  final List<InlineSpan> spans = [];
  
  // Regex for **text** (bold)
  final regex = RegExp(r'\*\*([^*]+?)\*\*');
  
  int lastEnd = 0;
  
  for (final match in regex.allMatches(line)) {
    // Add text before match
    if (match.start > lastEnd) {
      final beforeText = line.substring(lastEnd, match.start);
      spans.add(TextSpan(
        text: beforeText,
        style: TextStyle(
          color: isDark ? Colors.grey[100] : Colors.grey[800],
        ),
      ));
    }
    
    // Add bold text
    spans.add(TextSpan(
      text: match.group(1)!,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    ));
    
    lastEnd = match.end;
  }
  
  // Add remaining text
  if (lastEnd < line.length) {
    final remainingText = line.substring(lastEnd);
    spans.add(TextSpan(
      text: remainingText,
      style: TextStyle(
        color: isDark ? Colors.grey[100] : Colors.grey[800],
      ),
    ));
  }
  
  return spans;
}