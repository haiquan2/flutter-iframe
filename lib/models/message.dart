class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final List<String>? files;

  const Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.files,
  });

  Message copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
    List<String>? files,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      files: files ?? this.files,
    );
  }
}
