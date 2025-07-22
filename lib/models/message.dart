import 'dart:typed_data';

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final Uint8List? imageBytes;
  final String? modelName;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.imageBytes,
    this.modelName,
  });

  Message copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
    Uint8List? imageBytes,
    String? modelName,
  }) {
    return Message(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      imageBytes: imageBytes ?? this.imageBytes,
      modelName: modelName ?? this.modelName,
    );
  }

  // Convert to JSON for potential storage
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'modelUsed': modelName,
      // Note: imageBytes not included in JSON for storage efficiency
    };
  }

  // Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      isLoading: json['isLoading'] ?? false,
      modelName: json['modelName'],
    );
  }
}
