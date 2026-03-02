import 'package:flutter/material.dart';
import 'package:client/src/models/chatmessage_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int? currentUserId;

  const ChatBubble({super.key, required this.message, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && message.userId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigo.shade500 : Colors.blue.shade50,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(!isMe ? 0 : 16),
            bottomRight: Radius.circular(!isMe ? 16 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
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
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(@${message.username})',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
