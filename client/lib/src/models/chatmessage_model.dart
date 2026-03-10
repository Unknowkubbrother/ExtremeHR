class ChatMessage {
  static final RegExp _evaluationPrefixPattern = RegExp(
    r'^\[HR_LOCAL_EVAL:(\d+)\]\s*',
  );
  static final RegExp _evaluationBodyPattern = RegExp(
    r'^Evaluation Score:\s*([0-9]+(?:\.[0-9]+)?)\s*[\r\n]+Reason:\s*(.+)$',
    dotAll: true,
  );

  final String role;
  final String time;
  final String text;
  final int userId;
  final String username;
  final String fullName;
  final int? questionId;

  const ChatMessage({
    required this.role,
    required this.time,
    required this.text,
    required this.userId,
    required this.username,
    required this.fullName,
    this.questionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'time': time,
      'text': text,
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'question_id': questionId,
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
      questionId: json['question_id'] as int?,
    );
  }

  factory ChatMessage.fromApiJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role']?.toString() ?? '',
      time: json['time']?.toString() ?? '0:00',
      text: json['text']?.toString() ?? '',
      userId: json['user_id'] is num
          ? (json['user_id'] as num).toInt()
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      questionId: json['question_id'] is num
          ? (json['question_id'] as num).toInt()
          : int.tryParse(json['question_id']?.toString() ?? ''),
    );
  }

  String get displayText {
    final match = _evaluationPrefixPattern.firstMatch(text);
    if (match == null) {
      return text;
    }
    return text.substring(match.end).trimLeft();
  }

  int? get evaluationQuestionId {
    final match = _evaluationPrefixPattern.firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  bool get isEvaluationMessage {
    return role.toUpperCase() == 'AI' &&
        _evaluationBodyPattern.hasMatch(displayText.trim());
  }

  double? get evaluationScore {
    final match = _evaluationBodyPattern.firstMatch(displayText.trim());
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1) ?? '');
  }

  String? get evaluationReason {
    final match = _evaluationBodyPattern.firstMatch(displayText.trim());
    if (match == null) {
      return null;
    }
    return match.group(2)?.trim();
  }
}
