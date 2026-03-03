import 'package:flutter/material.dart';
import 'package:client/src/models/chatmessage_model.dart';
import 'package:client/src/components/MeetingPage/chatbubble.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/user_services.dart';
import 'dart:async';

class ChatMeeting extends StatefulWidget {
  final bool isMicOn;

  const ChatMeeting({super.key, required this.isMicOn});

  @override
  State<ChatMeeting> createState() => _ChatMeetingState();
}

class _ChatMeetingState extends State<ChatMeeting> {
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isAttempting = false;
  String? _currentUserRole;
  String? _currentUserName;
  int? _currentUserId;
  String? _currentUserFullName;
  String _currentText = "";
  String _lastDisplayedText = ""; // Debounce: skip if text didn't change
  bool _isNewMessage = true;
  bool _isInitialized = false;
  Timer? _silenceTimer;
  Timer? _guardianTimer;
  int _committedLength =
      0; // Track how much text is already in previous bubbles

  final List<ChatMessage> _messages = [
    const ChatMessage(
      role: "HR",
      time: "0:32",
      text: "Tell me about your experience with React at scale.",
      userId: 1,
      username: "hr_manager",
      fullName: "HR Manager",
    ),
    const ChatMessage(
      role: "Candidate",
      time: "0:45",
      text:
          "I've built several large-scale React applications handling millions of users. At my previous company, I architected a micro-frontend system that reduced bundle sizes by 40%.",
      userId: 2,
      username: "candidate_01",
      fullName: "Candidate Profile",
    ),
    const ChatMessage(
      role: "HR",
      time: "2:15",
      text: "How do you handle state management in complex applications?",
      userId: 1,
      username: "hr_manager",
      fullName: "HR Manager",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initIdentity();
    _initSpeech();
    _startGuardian();
  }

  void _startGuardian() {
    _guardianTimer?.cancel();
    _guardianTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted &&
          widget.isMicOn &&
          !_speechToText.isListening &&
          !_isAttempting) {
        debugPrint(
          'STT Guardian: Mic should be ON but is OFF. Force restarting...',
        );
        _listen();
      }
    });
  }

  Future<void> _initIdentity() async {
    try {
      final storage = AuthStorage();
      final token = await storage.getToken();
      if (token != null) {
        final user = await UserServices().me(token);
        if (mounted) {
          setState(() {
            _currentUserId = user.id;
            _currentUserName = user.username;
            _currentUserRole = user.role.toUpperCase() == "HR"
                ? "HR"
                : "Candidate";
            _currentUserFullName =
                user.username; // Use username as fallback for full name
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching identity: $e');
      // Fallback
      if (mounted) {
        setState(() {
          _currentUserRole = "HR";
          _currentUserId = 1;
        });
      }
    }
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    bool available = await _speechToText.initialize(
      onStatus: _handleStatus,
      onError: (err) {
        debugPrint('STT Error: ${err.errorMsg}');
        _handleStatus('done');
      },
    );
    if (mounted) {
      setState(() {
        _isInitialized = available;
      });
    }
  }

  void _handleStatus(String status) {
    debugPrint('STT Status: $status (Mic: ${widget.isMicOn})');
    if (status == 'listening') {
      _isAttempting = false;
      if (mounted) setState(() => _isListening = true);
    } else if (status == 'done' || status == 'notListening') {
      _isAttempting = false;

      // When engine restarts naturally, reset committed offset
      if (mounted) {
        _committedLength = 0;
        _isNewMessage = true;
        _currentText = "";
      }

      // PROTECT UI: Keep _isListening TRUE if the widget mic is still ON.
      if (mounted && !widget.isMicOn) {
        setState(() => _isListening = false);
      }

      // INSTANT RECOVERY:
      if (mounted && widget.isMicOn) {
        _listen(); // Re-trigger immediately
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatMeeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMicOn != oldWidget.isMicOn) {
      if (widget.isMicOn) {
        // Mic turned ON — full reset and start fresh
        _committedLength = 0;
        _isNewMessage = true;
        _currentText = "";
        _lastDisplayedText = "";
        _isAttempting = false;
        _isListening = false;
        _silenceTimer?.cancel();
        _listen();
      } else {
        // Mic turned OFF — stop everything cleanly
        _silenceTimer?.cancel();
        _speechToText.stop();
        if (mounted) {
          setState(() {
            _isListening = false;
            _isAttempting = false;
            _isNewMessage = true;
            _currentText = "";
            _lastDisplayedText = "";
            _committedLength = 0;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _guardianTimer?.cancel();
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
    if (_isListening || _isAttempting || !widget.isMicOn || !_isInitialized) {
      return;
    }

    _isAttempting = true;
    debugPrint('STT: Starting listen loop...');

    try {
      await _speechToText.listen(
        localeId: 'th_TH',
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(hours: 1),
        listenFor: const Duration(hours: 1),
        cancelOnError: false,
        partialResults: true,
        onResult: (val) {
          if (!mounted || !widget.isMicOn) return;

          final fullText = val.recognizedWords;
          if (fullText.trim().isEmpty) return;

          // --- Noise filtering ---
          // Skip low-confidence results (0 means unknown/partial, so allow it)
          if (val.confidence > 0 && val.confidence < 0.3) {
            debugPrint('STT: Skipped low confidence (${val.confidence})');
            return;
          }

          // Extract only the NEW portion after committed text
          String newText;
          if (fullText.length > _committedLength) {
            newText = fullText.substring(_committedLength).trim();
          } else {
            newText = fullText.trim();
          }
          if (newText.isEmpty) return;

          // Debounce: skip if the displayed text hasn't actually changed
          if (newText == _lastDisplayedText) return;
          _lastDisplayedText = newText;

          // Reset silence timer — after 2s silence, commit this bubble
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            if (mounted && _currentText.isNotEmpty) {
              debugPrint('STT: Silence detected, finalizing bubble.');
              _committedLength = fullText.length;
              setState(() {
                _isNewMessage = true;
                _currentText = "";
                _lastDisplayedText = "";
              });
            }
          });

          setState(() {
            _currentText = newText;
            String time =
                "${DateTime.now().minute}:${DateTime.now().second.toString().padLeft(2, '0')}";

            if (_isNewMessage) {
              _messages.add(
                ChatMessage(
                  role: _currentUserRole ?? "HR",
                  time: time,
                  text: _currentText,
                  userId: _currentUserId ?? 1,
                  username: _currentUserName ?? "user",
                  fullName: _currentUserFullName ?? "User",
                ),
              );
              _isNewMessage = false;
            } else {
              _messages[_messages.length - 1] = ChatMessage(
                role: _currentUserRole ?? "HR",
                time: time,
                text: _currentText,
                userId: _currentUserId ?? 1,
                username: _currentUserName ?? "user",
                fullName: _currentUserFullName ?? "User",
              );
            }
          });
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        },
      );
    } catch (e) {
      debugPrint('STT Listen Exception: $e');
      _isAttempting = false;
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  message: _messages[index],
                  currentUserId: _currentUserId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
