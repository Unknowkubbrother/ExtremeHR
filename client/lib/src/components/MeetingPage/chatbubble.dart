import 'package:flutter/material.dart';
import 'package:client/src/models/chatmessage_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isHR = message.role == "HR";

    return Align(
      alignment: isHR ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isHR ? Colors.blue.shade50 : Colors.indigo.shade500,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isHR ? 0 : 16),
            bottomRight: Radius.circular(isHR ? 16 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: isHR
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            isHR
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.role,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isHR ? Colors.black87 : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isHR ? Colors.black54 : Colors.white70,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        message.role,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isHR ? Colors.black87 : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isHR ? Colors.black54 : Colors.white70,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(color: isHR ? Colors.black87 : Colors.white),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
