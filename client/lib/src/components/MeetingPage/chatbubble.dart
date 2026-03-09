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
    final bubbleColor = isAi
        ? Colors.amber.shade50
        : (isMe ? Colors.indigo.shade500 : Colors.blue.shade50);
    final primaryTextColor = isMe ? Colors.white : Colors.black87;
    final secondaryTextColor = isMe ? Colors.white70 : Colors.black54;
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
              message.text,
              style: TextStyle(color: primaryTextColor),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
