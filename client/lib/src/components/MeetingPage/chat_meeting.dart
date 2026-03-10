import 'dart:async';

import 'package:client/src/components/MeetingPage/chatbubble.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/models/chatmessage_model.dart';
import 'package:client/src/models/interview_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:client/src/services/signaling_service.dart';
import 'package:client/src/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatMeeting extends StatefulWidget {
  final bool isMicOn;
  final bool canSpeak;
  final bool isCallConnected;
  final SignalingService? signalingService;
  final String? roomId;

  const ChatMeeting({
    super.key,
    required this.isMicOn,
    required this.canSpeak,
    required this.isCallConnected,
    this.signalingService,
    this.roomId,
  });

  @override
  State<ChatMeeting> createState() => ChatMeetingState();
}

class ChatMeetingState extends State<ChatMeeting> {
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final InterviewService _interviewService = InterviewService();

  static const String _aiRole = 'AI';
  static const String _aiUsername = 'ai';
  static const String _aiFullName = 'AI';

  bool _isListening = false;
  bool _isAttempting = false;
  bool _isNewMessage = true;
  bool _isInitialized = false;
  bool _isEvaluating = false;
  bool _isLoadingHistory = false;
  bool _hasLoadedHistory = false;

  String? _currentUserRole;
  String? _currentUserName;
  int? _currentUserId;
  String? _currentUserFullName;

  String _currentText = '';
  String _lastDisplayedText = '';
  int _committedLength = 0;

  Timer? _silenceTimer;
  Timer? _guardianTimer;
  Timer? _listenRestartTimer;
  int _sttSessionToken = 0;

  final List<ChatMessage> _messages = [];

  bool get _canListen =>
      widget.isMicOn &&
      widget.canSpeak &&
      widget.isCallConnected &&
      _isInitialized;

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
          _canListen &&
          !_speechToText.isListening &&
          !_isAttempting &&
          !(_listenRestartTimer?.isActive ?? false)) {
        debugPrint(
          'STT Guardian: Mic should be ON but is OFF. Force restarting...',
        );
        _scheduleListenStart(const Duration(milliseconds: 300));
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
        await _loadChatHistory(token);
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

  Future<void> _loadChatHistory(String token) async {
    if (_hasLoadedHistory || _isLoadingHistory || widget.roomId == null) {
      return;
    }

    _isLoadingHistory = true;

    try {
      final historyMessages = await _interviewService.getChatHistory(
        token,
        widget.roomId!,
      );

      if (!mounted) {
        return;
      }

      final existingKeys = _messages.map(_messageKey).toSet();
      final newMessages = historyMessages
          .where((message) => !existingKeys.contains(_messageKey(message)))
          .toList();

      setState(() {
        _messages.addAll(newMessages);
        _hasLoadedHistory = true;
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    } finally {
      _isLoadingHistory = false;
    }
  }

  String _messageKey(ChatMessage message) {
    return [
      message.role,
      message.userId.toString(),
      message.time,
      message.text,
      message.questionId?.toString() ?? '',
    ].join('|');
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
      'STT Status: $status (Mic: ${widget.isMicOn}, Ready: ${widget.canSpeak}, Connected: ${widget.isCallConnected})',
    );

    if (status == 'listening') {
      if (!_canListen) {
        return;
      }

      _isAttempting = false;
      if (mounted) {
        setState(() => _isListening = true);
      }
      return;
    }

    if (status != 'done' && status != 'notListening') {
      return;
    }

    if (_canListen && _speechToText.isListening) {
      return;
    }

    _isAttempting = false;
    _resetDraftState();

    if (mounted && !_canListen) {
      setState(() => _isListening = false);
    }

    if (mounted && _canListen) {
      _scheduleListenStart();
    }
  }

  void _scheduleListenStart([
    Duration delay = const Duration(milliseconds: 800),
  ]) {
    _listenRestartTimer?.cancel();
    if (!_canListen) {
      return;
    }

    _listenRestartTimer = Timer(delay, () {
      if (!mounted ||
          !_canListen ||
          _speechToText.isListening ||
          _isAttempting) {
        return;
      }
      _listen();
    });
  }

  @override
  void didUpdateWidget(covariant ChatMeeting oldWidget) {
    super.didUpdateWidget(oldWidget);

    final micTurnedOn = widget.isMicOn && !oldWidget.isMicOn;
    final micTurnedOff = !widget.isMicOn && oldWidget.isMicOn;
    final speakingEnabled = widget.canSpeak && !oldWidget.canSpeak;
    final speakingDisabled = !widget.canSpeak && oldWidget.canSpeak;
    final callConnected = widget.isCallConnected && !oldWidget.isCallConnected;
    final callDisconnected =
        !widget.isCallConnected && oldWidget.isCallConnected;

    if (micTurnedOff) {
      _pauseForMutedMicrophone(removeDraft: true);
    }

    if (speakingDisabled || callDisconnected) {
      _stopListeningSession(removeDraft: true);
    }

    if ((micTurnedOn || speakingEnabled || callConnected) && _canListen) {
      _resetDraftState();
      _isAttempting = false;
      _silenceTimer?.cancel();
      _listenRestartTimer?.cancel();

      if (!_speechToText.isListening) {
        _isListening = false;
        _scheduleListenStart();
      }
    }
  }

  void _resetDraftState() {
    _committedLength = 0;
    _isNewMessage = true;
    _currentText = '';
    _lastDisplayedText = '';
  }

  void _invalidateSpeechSession() {
    _sttSessionToken += 1;
    _silenceTimer?.cancel();
    _listenRestartTimer?.cancel();
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
    _invalidateSpeechSession();
    _speechToText.cancel();
    _clearDraftState(removeDraft: removeDraft, markIdle: true);
  }

  void _stopListeningSession({required bool removeDraft}) {
    _invalidateSpeechSession();
    _speechToText.cancel();
    _clearDraftState(removeDraft: removeDraft, markIdle: true);
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _guardianTimer?.cancel();
    _listenRestartTimer?.cancel();
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

  ChatMessage _buildAiChatMessage(
    String text, {
    String? time,
    int? questionId,
  }) {
    return ChatMessage(
      role: _aiRole,
      time: time ?? _currentTimeLabel(),
      text: text,
      userId: _currentUserId ?? 1,
      username: _aiUsername,
      fullName: _aiFullName,
      questionId: questionId,
    );
  }

  void _pushAiMessage(String text, {int? questionId}) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || !mounted || !widget.canSpeak) {
      return;
    }

    final time = _currentTimeLabel();

    setState(() {
      _messages.add(
        _buildAiChatMessage(trimmedText, time: time, questionId: questionId),
      );
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
        'question_id': questionId,
        'is_final': true,
        'timestamp': DateTime.now().toIso8601String(),
        'time': time,
      });
    }
  }

  void addAiMessage(String text, int? questionId) {
    _pushAiMessage(text, questionId: questionId);
  }

  void _addLocalAiMessage(String text, {int? questionId}) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _messages.add(
        _buildAiChatMessage(
          trimmedText,
          time: _currentTimeLabel(),
          questionId: questionId,
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _listen() async {
    if (_isListening || _isAttempting || !_canListen) {
      return;
    }

    final sessionToken = ++_sttSessionToken;
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
          if (sessionToken != _sttSessionToken) {
            return;
          }

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
            if (sessionToken != _sttSessionToken) {
              return;
            }

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
      if (sessionToken == _sttSessionToken) {
        _isAttempting = false;
      }
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
          questionId: message['question_id'] is num
              ? (message['question_id'] as num).toInt()
              : int.tryParse(message['question_id']?.toString() ?? ''),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  bool _isCandidateRole(String role) {
    return role.toUpperCase() == 'CANDIDATE';
  }

  int? _getLatestEvaluableQuestionId() {
    for (var index = _messages.length - 1; index >= 0; index--) {
      final message = _messages[index];
      if (message.role.toUpperCase() == _aiRole && message.questionId != null) {
        final questionId = message.questionId!;
        return _hasEvaluationForQuestion(questionId, startIndex: index + 1)
            ? null
            : questionId;
      }
    }
    return null;
  }

  bool _hasEvaluationForQuestion(int questionId, {required int startIndex}) {
    for (var index = startIndex; index < _messages.length; index++) {
      if (_messages[index].evaluationQuestionId == questionId) {
        return true;
      }
    }
    return false;
  }

  int _getLatestEvaluableQuestionIndex(int questionId) {
    for (var index = _messages.length - 1; index >= 0; index--) {
      final message = _messages[index];
      if (message.role.toUpperCase() == _aiRole &&
          message.questionId == questionId) {
        return index;
      }
    }
    return -1;
  }

  String _getCandidateAnswerForQuestion(int questionId) {
    final questionIndex = _getLatestEvaluableQuestionIndex(questionId);
    if (questionIndex == -1) {
      return '';
    }

    final answerParts = <String>[];
    for (var index = questionIndex + 1; index < _messages.length; index++) {
      final message = _messages[index];
      if (_isCandidateRole(message.role)) {
        final text = message.text.trim();
        if (text.isNotEmpty) {
          answerParts.add(text);
        }
      }
    }

    return answerParts.join(' ').trim();
  }

  String _formatEvaluationText(QuestionEvaluationResult result) {
    return '[HR_LOCAL_EVAL:${result.questionId}] Evaluation Score: ${result.score.toStringAsFixed(2)}\nReason: ${result.reason}';
  }

  Future<void> _evaluateQuestion() async {
    final evaluableQuestionId = _getLatestEvaluableQuestionId();
    if (evaluableQuestionId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No evaluable AI question found')),
        );
      }
      return;
    }

    final candidateAnswer = _getCandidateAnswerForQuestion(evaluableQuestionId);
    if (candidateAnswer.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidate answer not found yet')),
        );
      }
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      final storage = AuthStorage();
      final token = await storage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final result = await _interviewService.evaluateQuestion(
        token,
        evaluableQuestionId,
        candidateAnswer,
      );

      if (!mounted) {
        return;
      }

      _addLocalAiMessage(_formatEvaluationText(result));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEvaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHrViewer = (_currentUserRole ?? '').toUpperCase() == 'HR';
    final evaluableQuestionId = _getLatestEvaluableQuestionId();
    final hasCandidateAnswer = evaluableQuestionId != null
        ? _getCandidateAnswerForQuestion(evaluableQuestionId).isNotEmpty
        : false;
    final showEvaluateButton =
        isHrViewer && evaluableQuestionId != null && hasCandidateAnswer;

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
              itemCount: showEvaluateButton
                  ? _messages.length + 1
                  : _messages.length,
              itemBuilder: (context, index) {
                if (showEvaluateButton && index == _messages.length) {
                  return Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: SizedBox(
                        width: 240,
                        child: ElevatedButton.icon(
                          onPressed: _isEvaluating ? null : _evaluateQuestion,
                          icon: _isEvaluating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.analytics_outlined, size: 20),
                          label: Text(
                            _isEvaluating
                                ? "Evaluating..."
                                : "Evaluate Question",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

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
