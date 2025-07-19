import 'package:flutter/material.dart';
import 'package:flutter_openai_stream/models/message.dart';

Widget formattedMessage(BuildContext context, bool isDark, Message message) {
  return Container(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseMarkdownToWidgets(message.content, isDark, context),
    ),
  );
}

List<Widget> _parseMarkdownToWidgets(String markdown, bool isDark, BuildContext context) {
  final lines = markdown.split('\n');
  final List<Widget> widgets = [];
  
  bool inCodeBlock = false;
  bool inTable = false;
  String codeBlockLanguage = '';
  List<String> codeBlockLines = [];
  List<String> tableLines = [];
  List<String> currentParagraph = [];
  
  void _flushParagraph() {
    if (currentParagraph.isNotEmpty) {
      final paragraphText = currentParagraph.join('\n');
      widgets.add(
        SelectableText.rich(
          _parseInlineMarkdown(paragraphText, isDark),
          style: TextStyle(
            color: isDark ? Colors.grey[100] : Colors.grey[800],
            fontSize: 14,
            height: 1.5,
            letterSpacing: 0.1,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      currentParagraph.clear();
    }
  }
  
  void _flushTable() {
    if (tableLines.isNotEmpty) {
      widgets.add(_createTable(tableLines, isDark));
      widgets.add(const SizedBox(height: 16));
      tableLines.clear();
    }
  }
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    
    // Handle code blocks
    if (line.trim().startsWith('```')) {
      _flushParagraph();
      _flushTable();
      
      if (!inCodeBlock) {
        inCodeBlock = true;
        codeBlockLanguage = line.trim().substring(3).trim();
        codeBlockLines = [];
      } else {
        inCodeBlock = false;
        widgets.add(_createCodeBlock(codeBlockLines.join('\n'), codeBlockLanguage, isDark));
        widgets.add(const SizedBox(height: 16));
      }
      continue;
    }
    
    if (inCodeBlock) {
      codeBlockLines.add(line);
      continue;
    }
    
    // Handle tables
    if (_isTableRow(line)) {
      _flushParagraph();
      inTable = true;
      tableLines.add(line);
      continue;
    } else if (inTable) {
      _flushTable();
      inTable = false;
    }
    
    // Handle other elements
    if (line.trim().isEmpty) {
      _flushParagraph();
      continue;
    } else if (_isHeader(line)) {
      _flushParagraph();
      widgets.add(_createHeaderWidget(line, isDark));
      widgets.add(const SizedBox(height: 12));
    } else if (_isBulletPoint(line)) {
      _flushParagraph();
      widgets.add(_createBulletPointWidget(line, isDark));
      widgets.add(const SizedBox(height: 4));
    } else if (_isNumberedList(line)) {
      _flushParagraph();
      widgets.add(_createNumberedPointWidget(line, isDark));
      widgets.add(const SizedBox(height: 4));
    } else if (_isBlockquote(line)) {
      _flushParagraph();
      widgets.add(_createBlockquoteWidget(line, isDark));
      widgets.add(const SizedBox(height: 8));
    } else {
      currentParagraph.add(line);
    }
  }
  
  // Flush remaining content
  _flushParagraph();
  _flushTable();
  
  // Remove trailing spacing
  if (widgets.isNotEmpty && widgets.last is SizedBox) {
    widgets.removeLast();
  }
  
  return widgets;
}

bool _isTableRow(String line) {
  return line.trim().contains('|') && line.trim().length > 1;
}

bool _isHeader(String line) {
  return line.trim().startsWith('#');
}

bool _isBulletPoint(String line) {
  return RegExp(r'^\s*[\*\-\+]\s+').hasMatch(line);
}

bool _isNumberedList(String line) {
  return RegExp(r'^\s*\d+\.\s+').hasMatch(line);
}

bool _isBlockquote(String line) {
  return line.trim().startsWith('>');
}

Widget _createTable(List<String> tableLines, bool isDark) {
  if (tableLines.isEmpty) return const SizedBox.shrink();
  
  // Parse table data
  List<List<String>> rows = [];
  bool hasHeader = false;
  
  for (int i = 0; i < tableLines.length; i++) {
    final line = tableLines[i].trim();
    
    // Skip separator lines (e.g., |---|---|)
    if (line.contains('---') || line.contains('===')) {
      hasHeader = true;
      continue;
    }
    
    // Parse row
    List<String> cells = line
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
    
    if (cells.isNotEmpty) {
      rows.add(cells);
    }
  }
  
  if (rows.isEmpty) return const SizedBox.shrink();
  
  // Determine column count
  int maxColumns = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        // Header row (if exists)
        if (hasHeader && rows.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: _buildTableRow(rows[0], maxColumns, isDark, isHeader: true),
          ),
        
        // Data rows
        ...rows.skip(hasHeader ? 1 : 0).map((row) => 
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  width: 0.5,
                ),
              ),
            ),
            child: _buildTableRow(row, maxColumns, isDark),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTableRow(List<String> cells, int maxColumns, bool isDark, {bool isHeader = false}) {
  return IntrinsicHeight(
    child: Row(
      children: List.generate(maxColumns, (index) {
        final cellContent = index < cells.length ? cells[index] : '';
        
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                right: index < maxColumns - 1
                    ? BorderSide(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        width: 0.5,
                      )
                    : BorderSide.none,
              ),
            ),
            child: SelectableText.rich(
              _parseInlineMarkdown(cellContent, isDark),
              style: TextStyle(
                color: isDark ? Colors.grey[100] : Colors.grey[800],
                fontSize: 13,
                fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                height: 1.4,
              ),
            ),
          ),
        );
      }),
    ),
  );
}

Widget _createHeaderWidget(String line, bool isDark) {
  final match = RegExp(r'^(#{1,6})\s*(.*)').firstMatch(line.trim());
  if (match == null) return Text(line);
  
  final level = match.group(1)!.length;
  final text = match.group(2)!;
  
  double fontSize;
  FontWeight fontWeight;
  
  switch (level) {
    case 1:
      fontSize = 24;
      fontWeight = FontWeight.w700;
      break;
    case 2:
      fontSize = 20;
      fontWeight = FontWeight.w600;
      break;
    case 3:
      fontSize = 18;
      fontWeight = FontWeight.w600;
      break;
    case 4:
      fontSize = 16;
      fontWeight = FontWeight.w500;
      break;
    case 5:
      fontSize = 14;
      fontWeight = FontWeight.w500;
      break;
    default:
      fontSize = 13;
      fontWeight = FontWeight.w500;
  }
  
  return SelectableText.rich(
    _parseInlineMarkdown(text, isDark),
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? Colors.white : Colors.black87,
      height: 1.3,
    ),
  );
}

Widget _createBulletPointWidget(String line, bool isDark) {
  final match = RegExp(r'^(\s*)([\*\-\+])\s+(.*)').firstMatch(line);
  if (match == null) return Text(line);
  
  final indent = match.group(1)!.length;
  final content = match.group(3)!;
  
  return Padding(
    padding: EdgeInsets.only(left: indent * 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: SelectableText.rich(
            _parseInlineMarkdown(content, isDark),
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

Widget _createNumberedPointWidget(String line, bool isDark) {
  final match = RegExp(r'^(\s*)(\d+)\.\s+(.*)').firstMatch(line);
  if (match == null) return Text(line);
  
  final indent = match.group(1)!.length;
  final number = match.group(2)!;
  final content = match.group(3)!;
  
  return Padding(
    padding: EdgeInsets.only(left: indent * 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: TextStyle(
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: SelectableText.rich(
            _parseInlineMarkdown(content, isDark),
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

Widget _createBlockquoteWidget(String line, bool isDark) {
  final content = line.trim().substring(1).trim();
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          width: 4,
        ),
      ),
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
    ),
    child: SelectableText.rich(
      _parseInlineMarkdown(content, isDark),
      style: TextStyle(
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
        fontStyle: FontStyle.italic,
        fontSize: 14,
        height: 1.5,
      ),
    ),
  );
}

Widget _createCodeBlock(String code, String language, bool isDark) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (language.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              language,
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SelectableText(
          code,
          style: TextStyle(
            fontFamily: 'Courier',
            color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

TextSpan _parseInlineMarkdown(String text, bool isDark) {
  final List<TextSpan> spans = [];
  
  // Combined regex for all inline formatting
  final regex = RegExp(
    r'(\*\*\*([^*]+)\*\*\*)|'  // Bold italic
    r'(\*\*([^*]+)\*\*)|'      // Bold
    r'(\*([^*]+)\*)|'          // Italic
    r'(`([^`]+)`)|'            // Inline code
    r'(~~([^~]+)~~)|'          // Strikethrough
    r'(\[([^\]]+)\]\(([^)]+)\))', // Links
  );
  
  int lastEnd = 0;
  
  for (final match in regex.allMatches(text)) {
    // Add text before match
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: TextStyle(
          color: isDark ? Colors.grey[100] : Colors.grey[800],
        ),
      ));
    }
    
    // Determine which group matched and style accordingly
    if (match.group(1) != null) {
      // Bold italic ***text***
      spans.add(TextSpan(
        text: match.group(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ));
    } else if (match.group(3) != null) {
      // Bold **text**
      spans.add(TextSpan(
        text: match.group(4),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ));
    } else if (match.group(5) != null) {
      // Italic *text*
      spans.add(TextSpan(
        text: match.group(6),
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.grey[100] : Colors.grey[700],
        ),
      ));
    } else if (match.group(7) != null) {
      // Inline code `code`
      spans.add(TextSpan(
        text: match.group(8),
        style: TextStyle(
          fontFamily: 'Courier',
          backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
          fontSize: 13,
        ),
      ));
    } else if (match.group(9) != null) {
      // Strikethrough ~~text~~
      spans.add(TextSpan(
        text: match.group(10),
        style: TextStyle(
          decoration: TextDecoration.lineThrough,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ));
    } else if (match.group(11) != null) {
      // Links [text](url)
      spans.add(TextSpan(
        text: match.group(12),
        style: TextStyle(
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
          decoration: TextDecoration.underline,
        ),
      ));
    }
    
    lastEnd = match.end;
  }
  
  // Add remaining text
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: TextStyle(
        color: isDark ? Colors.grey[100] : Colors.grey[800],
      ),
    ));
  }
  
  return TextSpan(children: spans.isEmpty ? [TextSpan(text: text)] : spans);
}