import 'package:flutter/material.dart';
import 'package:client/src/models/chatmessage_model.dart';
import 'package:client/src/components/MeetingPage/chatbubble.dart';

class ChatMeeting extends StatefulWidget {
  const ChatMeeting({super.key});

  @override
  State<ChatMeeting> createState() => _ChatMeetingState();
}

class _ChatMeetingState extends State<ChatMeeting> {
  final messages = const [
    ChatMessage(
      role: "HR",
      time: "0:32",
      text: "Tell me about your experience with React at scale.",
    ),
    ChatMessage(
      role: "Candidate",
      time: "0:45",
      text:
          "I've built several large-scale React applications handling millions of users. At my previous company, I architected a micro-frontend system that reduced bundle sizes by 40%.",
    ),
    ChatMessage(
      role: "HR",
      time: "2:15",
      text: "How do you handle state management in complex applications?",
    ),
    ChatMessage(
      role: "Candidate",
      time: "2:45",
      text:
          "I've built several large-scale React applications handling millions of users. At my previous company, I architected a micro-frontend system that reduced bundle sizes by 40%.",
    ),
    ChatMessage(
      role: "HR",
      time: "3:15",
      text: "How do you handle state management in complex applications?",
    ),
    ChatMessage(
      role: "Candidate",
      time: "3:45",
      text:
          "I've built several large-scale React applications handling millions of users. At my previous company, I architected a micro-frontend system that reduced bundle sizes by 40%.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ChatBubble(message: messages[index]);
        },
      ),
    );
  }
}
