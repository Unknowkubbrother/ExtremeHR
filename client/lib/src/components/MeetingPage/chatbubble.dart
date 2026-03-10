import 'package:flutter/material.dart';
import 'package:client/src/models/chatmessage_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int? currentUserId;

  const ChatBubble({super.key, required this.message, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isAi = message.role.toUpperCase() == 'AI';
    final isMe = currentUserId != null && message.userId == currentUserId;
    final isRightAligned = isMe;

    if (message.isEvaluationMessage) {
      return _EvaluationBubble(
        message: message,
        isRightAligned: isRightAligned,
      );
    }

    final bubbleColor = isAi
        ? Colors.amber.shade50
        : (isMe ? Colors.indigo.shade500 : Colors.blue.shade50);
    final primaryTextColor = isAi
        ? Colors.black87
        : (isMe ? Colors.white : Colors.black87);
    final secondaryTextColor = isAi
        ? Colors.black45
        : (isMe ? Colors.white70 : Colors.black54);
    final nameColor = isAi ? Colors.orange.shade800 : primaryTextColor;

    return Align(
      alignment: isRightAligned ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isRightAligned ? 16 : 0),
            bottomRight: Radius.circular(isRightAligned ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isRightAligned
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: nameColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(@${message.username})',
                  style: TextStyle(fontSize: 10, color: secondaryTextColor),
                ),
                const SizedBox(width: 8),
                Text(
                  message.time,
                  style: TextStyle(fontSize: 10, color: secondaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.displayText,
              style: TextStyle(color: primaryTextColor),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isRightAligned;

  const _EvaluationBubble({
    required this.message,
    required this.isRightAligned,
  });

  Color _scoreColor(double score) {
    if (score >= 0.75) {
      return Colors.green.shade700;
    }
    if (score >= 0.5) {
      return Colors.orange.shade700;
    }
    return Colors.red.shade700;
  }

  String _formatScoreLabel(double score) {
    final scaledScore = score * 5;
    final hasDecimal =
        (scaledScore - scaledScore.roundToDouble()).abs() > 0.001;
    final scoreText = hasDecimal
        ? scaledScore.toStringAsFixed(1)
        : scaledScore.toStringAsFixed(0);
    return '$scoreText/5';
  }

  @override
  Widget build(BuildContext context) {
    final score = message.evaluationScore ?? 0;
    final reason = message.evaluationReason ?? message.displayText;
    final scoreColor = _scoreColor(score);

    return Align(
      alignment: isRightAligned ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EA),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isRightAligned ? 18 : 4),
            bottomRight: Radius.circular(isRightAligned ? 4 : 18),
          ),
          border: Border.all(color: const Color(0xFFFFE1A6)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 18,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Question Evaluation',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatScoreLabel(score),
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason,
                    style: const TextStyle(color: Colors.black87, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  message.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(@${message.username})',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const Spacer(),
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
