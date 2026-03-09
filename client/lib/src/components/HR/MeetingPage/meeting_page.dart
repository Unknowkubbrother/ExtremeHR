import 'package:client/src/components/shared/confirm.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/models/interview_model.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:client/src/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/MeetingPage/video_meeting.dart';
import 'package:client/src/components/MeetingPage/chat_meeting.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/services/signaling_service.dart';
import 'package:client/src/services/webrtc_service.dart';

class HRMeetingPage extends StatefulWidget {
  const HRMeetingPage({super.key, required this.id});

  final String id;

  @override
  State<HRMeetingPage> createState() => _HRMeetingPageState();
}

class _HRMeetingPageState extends State<HRMeetingPage> {
  bool _isMicOn = true;
  bool _isCameraOn = true;

  late SignalingService _signalingService;
  late WebRTCService _webrtcService;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isRemoteConnected = false;
  bool _isInitialized = false;

  String? _currentUserRole;
  int? _currentUserId;

  final GlobalKey<ChatMeetingState> _chatKey = GlobalKey<ChatMeetingState>();

  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authService = AuthStorage();

  Future<void> _endInterview() async {
    final token = await _authService.getToken();
    if (token != null) {
      await _interviewService.endInterview(token, widget.id);
    }
  }

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signalingService = SignalingService();
    _webrtcService = WebRTCService(_signalingService);

    try {
      final token = await _authService.getToken();
      if (token != null) {
        final user = await UserServices().me(token);
        _currentUserId = user.id;
        _currentUserRole = user.role.toLowerCase() == "hr" ? "hr" : "candidate";

        await _interviewService.getInterviewContext(token, widget.id);
      }
    } catch (e) {
      _currentUserId = 1;
      _currentUserRole = 'hr';
    }

    _webrtcService.onLocalStream = (stream) {
      if (mounted) setState(() => _localRenderer.srcObject = stream);
    };

    _webrtcService.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          _isRemoteConnected = true;
        });
      }
    };

    _signalingService.onMessageReceived = (message) {
      if (!mounted) return;
      if (message['type'] == 'webrtc_sdp') {
        if (message['sdp_type'] == 'offer') {
          _webrtcService.handleRemoteDescription('offer', message['sdp']);
          _webrtcService.createAnswer(widget.id, _currentUserId.toString());
        } else if (message['sdp_type'] == 'answer') {
          _webrtcService.handleRemoteDescription('answer', message['sdp']);
        }
      } else if (message['type'] == 'webrtc_ice') {
        _webrtcService.handleIceCandidate(message);
      } else if (message['type'] == 'user_left') {
        setState(() {
          _isRemoteConnected = false;
          _remoteRenderer.srcObject = null;
        });
      } else if (message['type'] == 'transcript') {
        _chatKey.currentState?.handleRemoteTranscript(message);
      }
    };

    _signalingService.connect(
      widget.id,
      _currentUserId.toString(),
      _currentUserRole!,
    );

    await _webrtcService.initLocalStream();
    await _webrtcService.initPeerConnection(
      widget.id,
      _currentUserId.toString(),
    );

    setState(() => _isInitialized = true);

    if (_currentUserRole == 'hr') {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _webrtcService.createOffer(widget.id, _currentUserId.toString());
        }
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    _signalingService.disconnect();
    super.dispose();
  }

  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    _webrtcService.toggleMicrophone(!_isMicOn);
  }

  void _toggleCamera() {
    setState(() => _isCameraOn = !_isCameraOn);
    _webrtcService.toggleCamera(!_isCameraOn);
  }

  Future<void> _openQuestionModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InterviewQuestionModal(
        interviewId: widget.id,
        interviewService: _interviewService,
        authService: _authService,
        onSelectQuestion: _handleSelectQuestion,
      ),
    );
  }

  void _handleSelectQuestion(String questionText) {
    _chatKey.currentState?.addAiMessage(questionText);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Interview")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            VideoMeeting(
              isCameraOn: _isCameraOn,
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
              isRemoteConnected: _isRemoteConnected,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CardContent(
                header: Row(
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "INTERVIEW TRANSCRIPT",
                            style: TextStyle(
                              fontSize: AppFontSizes.caption,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentUserRole == 'hr')
                      OutlinedButton.icon(
                        onPressed: _openQuestionModal,
                        icon: const Icon(Icons.psychology_alt_outlined),
                        label: const Text("AI Questions"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: AppFontSizes.small,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                child: Expanded(
                  child: ChatMeeting(
                    key: _chatKey,
                    isMicOn: _isMicOn,
                    signalingService: _signalingService,
                    roomId: widget.id,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mic Button
            _buildControlButton(
              icon: _isMicOn ? Icons.mic : Icons.mic_off,
              color: _isMicOn ? AppColors.primary : Colors.grey,
              onPressed: _toggleMic,
            ),
            const SizedBox(width: 8),
            // Camera Button
            _buildControlButton(
              icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
              color: _isCameraOn ? AppColors.primary : Colors.grey,
              onPressed: _toggleCamera,
            ),
            const SizedBox(width: 16),
            // End Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerousColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final bool? confirmed = await const ConfirmDialog(
                    title: "End Interview",
                    content: "Are you sure you want to end this interview?",
                    confirmText: "End",
                    cancelText: "Cancel",
                    confirmColor: AppColors.dangerousColor,
                    cancelColor: Colors.black54,
                  ).show(context);

                  if (confirmed != true) {
                    return;
                  }
                  if (!mounted) {
                    return;
                  }

                  await _endInterview();
                  if (!mounted) {
                    return;
                  }

                  navigator.pop();
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text(
                  "End",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _InterviewQuestionModal extends StatefulWidget {
  const _InterviewQuestionModal({
    required this.interviewId,
    required this.interviewService,
    required this.authService,
    required this.onSelectQuestion,
  });

  final String interviewId;
  final InterviewService interviewService;
  final AuthStorage authService;
  final ValueChanged<String> onSelectQuestion;

  @override
  State<_InterviewQuestionModal> createState() =>
      _InterviewQuestionModalState();
}

class _InterviewQuestionModalState extends State<_InterviewQuestionModal> {
  final TextEditingController _promptController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<GeneratedInterviewQuestion> _questions = const [];
  final Set<String> _selectedQuestions = <String>{};

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateQuestions() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _errorMessage =
            'กรุณาระบุหัวข้อหรือสิ่งที่ต้องการให้ระบบช่วยสร้างคำถาม';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    final token = await widget.authService.getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'ไม่พบ token สำหรับเรียกใช้งานระบบ';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _questions = const [];
      _selectedQuestions.clear();
    });

    try {
      final response = await widget.interviewService.generateInterviewQuestions(
        token,
        widget.interviewId,
        prompt,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _questions = response.questions;
        if (response.questions.isEmpty) {
          _errorMessage = 'ระบบยังไม่ส่งคำถามกลับมา';
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return difficulty.isEmpty ? '-' : difficulty;
    }
  }

  void _selectQuestion(GeneratedInterviewQuestion question) {
    final content = question.interviewQuestion.trim();
    if (content.isEmpty) {
      return;
    }

    widget.onSelectQuestion(content);

    setState(() {
      _selectedQuestions.add(content);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มคำถามลงในแชตแล้ว'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + viewInsets.bottom),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Questions',
                            style: TextStyle(
                              fontSize: AppFontSizes.subtitle,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryTo,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ระบุสิ่งที่ HR อยากโฟกัส แล้วให้ระบบช่วยสร้างคำถามสัมภาษณ์',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promptController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'HR Prompt',
                    hintText:
                        'เช่น ขอคำถามเกี่ยวกับผู้สมัครด้าน UI/UX, Flutter และการทำงานร่วมทีม',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateQuestions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _isLoading ? 'Generating...' : 'Generate Questions',
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerousColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.dangerousColor),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Generated Questions',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSizes.body,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_questions.length} items',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _questions.isEmpty
                      ? Center(
                          child: Text(
                            'ยังไม่มีคำถาม ให้กรอก prompt แล้วกด Generate Questions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _questions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            final isSelected = _selectedQuestions.contains(
                              question.interviewQuestion.trim(),
                            );

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.04,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question ${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    question.interviewQuestion,
                                    style: const TextStyle(
                                      fontSize: AppFontSizes.body,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryTo,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _QuestionMetaChip(
                                        icon: Icons.speed_outlined,
                                        label:
                                            'Difficulty: ${_formatDifficulty(question.difficulty)}',
                                      ),
                                      _QuestionMetaChip(
                                        icon: Icons.psychology_alt_outlined,
                                        label:
                                            'Competency: ${question.competency}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: isSelected
                                          ? null
                                          : () => _selectQuestion(question),
                                      icon: Icon(
                                        isSelected
                                            ? Icons.check_circle_outline
                                            : Icons.add_comment_outlined,
                                      ),
                                      label: Text(
                                        isSelected ? 'Added to Chat' : 'เลือก',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.22,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionMetaChip extends StatelessWidget {
  const _QuestionMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.small,
                color: AppColors.textPrimaryTo,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
