class ChatMessage {
  final String role;
  final String time;
  final String text;
  final int userId;
  final String username;
  final String fullName;

  const ChatMessage({
    required this.role,
    required this.time,
    required this.text,
    required this.userId,
    required this.username,
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'time': time,
      'text': text,
      'userId': userId,
      'username': username,
      'fullName': fullName,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      time: json['time'] as String,
      text: json['text'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
    );
  }
}
