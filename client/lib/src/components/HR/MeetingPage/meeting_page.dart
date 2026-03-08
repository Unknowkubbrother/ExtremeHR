import 'package:client/src/components/shared/confirm.dart';
import 'package:client/src/services/auth_storage.dart';
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
                header: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: AppColors.primary),
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
                  final bool? confirmed = await const ConfirmDialog(
                    title: "End Interview",
                    content: "Are you sure you want to end this interview?",
                    confirmText: "End",
                    cancelText: "Cancel",
                    confirmColor: AppColors.dangerousColor,
                    cancelColor: Colors.black54,
                  ).show(context);

                  if (confirmed == true && mounted) {
                    await _endInterview();
                    if (mounted) Navigator.pop(context);
                  }
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
