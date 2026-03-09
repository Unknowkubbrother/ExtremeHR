import 'dart:async';

import 'package:client/src/components/MeetingPage/chatbubble.dart';
import 'package:client/src/models/chatmessage_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/signaling_service.dart';
import 'package:client/src/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatMeeting extends StatefulWidget {
  final bool isMicOn;
  final bool canSpeak;
  final SignalingService? signalingService;
  final String? roomId;

  const ChatMeeting({
    super.key,
    required this.isMicOn,
    required this.canSpeak,
    this.signalingService,
    this.roomId,
  });

  @override
  State<ChatMeeting> createState() => ChatMeetingState();
}

class ChatMeetingState extends State<ChatMeeting> {
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  static const String _aiRole = 'AI';
  static const String _aiUsername = 'ai';
  static const String _aiFullName = 'AI';

  bool _isListening = false;
  bool _isAttempting = false;
  bool _isNewMessage = true;
  bool _isInitialized = false;

  String? _currentUserRole;
  String? _currentUserName;
  int? _currentUserId;
  String? _currentUserFullName;

  String _currentText = '';
  String _lastDisplayedText = '';
  int _committedLength = 0;

  Timer? _silenceTimer;
  Timer? _guardianTimer;

  final List<ChatMessage> _messages = [];

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
          widget.canSpeak &&
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
            _currentUserRole = user.role.toUpperCase() == 'HR'
                ? 'HR'
                : 'Candidate';
            _currentUserFullName = user.username;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching identity: $e');
      if (mounted) {
        setState(() {
          _currentUserRole = 'HR';
          _currentUserId = 1;
        });
      }
    }
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    final available = await _speechToText.initialize(
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
    debugPrint(
      'STT Status: $status (Mic: ${widget.isMicOn}, Ready: ${widget.canSpeak})',
    );

    if (status == 'listening') {
      _isAttempting = false;
      if (mounted) {
        setState(() => _isListening = true);
      }
      return;
    }

    if (status != 'done' && status != 'notListening') {
      return;
    }

    _isAttempting = false;
    _resetDraftState();

    if (mounted && (!widget.isMicOn || !widget.canSpeak)) {
      setState(() => _isListening = false);
    }

    if (mounted && widget.isMicOn && widget.canSpeak) {
      _listen();
    }
  }

  @override
  void didUpdateWidget(covariant ChatMeeting oldWidget) {
    super.didUpdateWidget(oldWidget);

    final micTurnedOn = widget.isMicOn && !oldWidget.isMicOn;
    final micTurnedOff = !widget.isMicOn && oldWidget.isMicOn;
    final speakingEnabled = widget.canSpeak && !oldWidget.canSpeak;
    final speakingDisabled = !widget.canSpeak && oldWidget.canSpeak;

    if (micTurnedOff) {
      _pauseForMutedMicrophone(removeDraft: true);
    }

    if (speakingDisabled) {
      _stopListeningSession(removeDraft: true);
    }

    if ((micTurnedOn || speakingEnabled) && widget.isMicOn && widget.canSpeak) {
      _resetDraftState();
      _isAttempting = false;
      _silenceTimer?.cancel();

      if (!_speechToText.isListening) {
        _isListening = false;
        _listen();
      }
    }
  }

  void _resetDraftState() {
    _committedLength = 0;
    _isNewMessage = true;
    _currentText = '';
    _lastDisplayedText = '';
  }

  void _clearDraftState({required bool removeDraft, required bool markIdle}) {
    if (!mounted) {
      _isAttempting = false;
      if (markIdle) {
        _isListening = false;
      }
      _resetDraftState();
      return;
    }

    setState(() {
      if (removeDraft &&
          _currentText.isNotEmpty &&
          _messages.isNotEmpty &&
          _messages.last.userId == (_currentUserId ?? 1) &&
          _messages.last.role == (_currentUserRole ?? 'HR')) {
        _messages.removeLast();
      }

      _isAttempting = false;
      if (markIdle) {
        _isListening = false;
      }
      _resetDraftState();
    });
  }

  void _pauseForMutedMicrophone({required bool removeDraft}) {
    _silenceTimer?.cancel();
    _clearDraftState(removeDraft: removeDraft, markIdle: false);
  }

  void _stopListeningSession({required bool removeDraft}) {
    _silenceTimer?.cancel();
    _speechToText.stop();
    _clearDraftState(removeDraft: removeDraft, markIdle: true);
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

  String _currentTimeLabel() {
    final now = DateTime.now();
    return '${now.minute}:${now.second.toString().padLeft(2, '0')}';
  }

  ChatMessage _buildAiChatMessage(String text, {String? time}) {
    return ChatMessage(
      role: _aiRole,
      time: time ?? _currentTimeLabel(),
      text: text,
      userId: _currentUserId ?? 1,
      username: _aiUsername,
      fullName: _aiFullName,
    );
  }

  void addAiMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || !mounted || !widget.canSpeak) {
      return;
    }

    final time = _currentTimeLabel();

    setState(() {
      _messages.add(_buildAiChatMessage(trimmedText, time: time));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    if (widget.signalingService != null &&
        widget.roomId != null &&
        _currentUserId != null) {
      widget.signalingService!.sendMessage({
        'type': 'transcript',
        'room_id': widget.roomId,
        'speaker_id': _currentUserId.toString(),
        'role': _aiRole,
        'text': trimmedText,
        'is_final': true,
        'timestamp': DateTime.now().toIso8601String(),
        'time': time,
      });
    }
  }

  void _listen() async {
    if (_isListening ||
        _isAttempting ||
        !widget.isMicOn ||
        !widget.canSpeak ||
        !_isInitialized) {
      return;
    }

    _isAttempting = true;
    debugPrint('STT: Starting listen loop...');

    try {
      await _speechToText.listen(
        localeId: 'th_TH',
        pauseFor: const Duration(hours: 1),
        listenFor: const Duration(hours: 1),
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
        onResult: (val) {
          if (!mounted || !widget.isMicOn || !widget.canSpeak) {
            return;
          }

          final fullText = val.recognizedWords;
          if (fullText.trim().isEmpty) {
            return;
          }

          if (val.confidence > 0 && val.confidence < 0.3) {
            debugPrint('STT: Skipped low confidence (${val.confidence})');
            return;
          }

          final newText = fullText.length > _committedLength
              ? fullText.substring(_committedLength).trim()
              : fullText.trim();

          if (newText.isEmpty || newText == _lastDisplayedText) {
            return;
          }

          _lastDisplayedText = newText;
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            if (!mounted || _currentText.isEmpty || !widget.canSpeak) {
              return;
            }

            debugPrint('STT: Silence detected, finalizing bubble.');
            _committedLength = fullText.length;

            if (widget.signalingService != null && widget.roomId != null) {
              widget.signalingService!.sendMessage({
                'type': 'transcript',
                'room_id': widget.roomId,
                'speaker_id': _currentUserId.toString(),
                'role': _currentUserRole,
                'text': _currentText,
                'is_final': true,
                'timestamp': DateTime.now().toIso8601String(),
                'time': _currentTimeLabel(),
              });
            }

            setState(() {
              _isNewMessage = true;
              _currentText = '';
              _lastDisplayedText = '';
            });
          });

          setState(() {
            _currentText = newText;
            final time = _currentTimeLabel();

            if (_isNewMessage) {
              _messages.add(
                ChatMessage(
                  role: _currentUserRole ?? 'HR',
                  time: time,
                  text: _currentText,
                  userId: _currentUserId ?? 1,
                  username: _currentUserName ?? 'user',
                  fullName: _currentUserFullName ?? 'User',
                ),
              );
              _isNewMessage = false;
            } else {
              _messages[_messages.length - 1] = ChatMessage(
                role: _currentUserRole ?? 'HR',
                time: time,
                text: _currentText,
                userId: _currentUserId ?? 1,
                username: _currentUserName ?? 'user',
                fullName: _currentUserFullName ?? 'User',
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

  void handleRemoteTranscript(Map<String, dynamic> message) {
    if (!mounted) {
      return;
    }

    final role = message['role']?.toString() ?? 'HR';
    final normalizedRole = role.toUpperCase();
    final isAi = normalizedRole == _aiRole;

    String username;
    String fullName;

    if (isAi) {
      username = _aiUsername;
      fullName = _aiFullName;
    } else if (role.toLowerCase() == 'hr') {
      username = 'HR Manager';
      fullName = 'HR Manager';
    } else {
      username = 'Candidate';
      fullName = 'Candidate Profile';
    }

    setState(() {
      _messages.add(
        ChatMessage(
          role: role,
          time: message['time']?.toString() ?? '0:00',
          text: message['text']?.toString() ?? '',
          userId: int.tryParse(message['speaker_id']?.toString() ?? '2') ?? 2,
          username: username,
          fullName: fullName,
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
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
          if (!widget.canSpeak)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'รออีกคนเข้าห้องอยู่ ระบบจะเริ่มฟังและบันทึกบทสนทนาเมื่อ HR และ Candidate เข้าครบแล้ว',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
