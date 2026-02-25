import 'package:flutter/material.dart';
import 'package:client/src/models/chatmessage_model.dart';
import 'package:client/src/components/MeetingPage/chatbubble.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class ChatMeeting extends StatefulWidget {
  const ChatMeeting({super.key});

  @override
  State<ChatMeeting> createState() => _ChatMeetingState();
}

class _ChatMeetingState extends State<ChatMeeting> {
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isHrTurn = true;
  String _currentText = "";
  bool _isNewMessage = true;

  final List<ChatMessage> _messages = [
    const ChatMessage(
      role: "HR",
      time: "0:32",
      text: "Tell me about your experience with React at scale.",
    ),
    const ChatMessage(
      role: "Candidate",
      time: "0:45",
      text:
          "I've built several large-scale React applications handling millions of users. At my previous company, I architected a micro-frontend system that reduced bundle sizes by 40%.",
    ),
    const ChatMessage(
      role: "HR",
      time: "2:15",
      text: "How do you handle state management in complex applications?",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
            if (_currentText.isNotEmpty) {
              _isHrTurn = !_isHrTurn;
              _isNewMessage = true;
              _currentText = "";
            }
          });
        }
      },
      onError: (errorNotification) {
        setState(() => _isListening = false);
      },
    );
    if (!available) {
      debugPrint("Speech recognition not available on this device.");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          localeId: 'th_TH',
          onResult: (val) => setState(() {
            _currentText = val.recognizedWords;
            String time =
                "${DateTime.now().minute}:${DateTime.now().second.toString().padLeft(2, '0')}";
            final role = _isHrTurn ? "HR" : "Candidate";

            if (_isNewMessage) {
              _messages.add(
                ChatMessage(role: role, time: time, text: _currentText),
              );
              _isNewMessage = false;
            } else {
              _messages[_messages.length - 1] = ChatMessage(
                role: role,
                time: time,
                text: _currentText,
              );
            }

            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
      if (_currentText.isNotEmpty) {
        _isHrTurn = !_isHrTurn;
        _isNewMessage = true;
        _currentText = "";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _listen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
