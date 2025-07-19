class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}
