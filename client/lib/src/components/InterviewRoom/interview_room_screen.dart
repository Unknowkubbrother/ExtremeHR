import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/signaling_service.dart';
import '../../services/webrtc_service.dart';
import '../../services/stt_service.dart';

class InterviewRoomScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String role; // 'hr' or 'candidate'

  const InterviewRoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.role,
  });

  @override
  State<InterviewRoomScreen> createState() => _InterviewRoomScreenState();
}

class _InterviewRoomScreenState extends State<InterviewRoomScreen> {
  late SignalingService _signalingService;
  late WebRTCService _webrtcService;
  late SpeechToTextService _sttService;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isRemoteConnected = false;

  final List<Map<String, dynamic>> _transcripts = [];

  double? _pipTop = 20;
  double? _pipRight = 20;
  double? _pipLeft;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signalingService = SignalingService();
    _webrtcService = WebRTCService(_signalingService);
    _sttService = SpeechToTextService(_signalingService);

    _webrtcService.onLocalStream = (stream) {
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = stream;
          // Ensure audio is enabled for local stream explicitly
          _webrtcService.toggleMicrophone(_isMuted);
        });
      }
    };

    _webrtcService.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          // IMPORTANT: explicitly enable remote audio track playout for iOS
          if (stream.getAudioTracks().isNotEmpty) {
            stream.getAudioTracks()[0].enabled = true;
          }
          _isRemoteConnected = true;
        });
      }
    };

    _signalingService.onMessageReceived = _handleMessage;

    _signalingService.connect(widget.roomId, widget.userId, widget.role);
    await _webrtcService.initLocalStream();
    await _webrtcService.initPeerConnection(widget.roomId, widget.userId);

    // Auto-start STT
    _sttService.startListening(widget.roomId, widget.userId, widget.role);

    // Give some time for peer connection to establish before offering (if HR)
    if (widget.role == 'hr') {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _webrtcService.createOffer(widget.roomId, widget.userId);
        }
      });
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (message['type'] == 'webrtc_sdp') {
      if (message['sdp_type'] == 'offer') {
        _webrtcService.handleRemoteDescription('offer', message['sdp']);
        _webrtcService.createAnswer(widget.roomId, widget.userId);
      } else if (message['sdp_type'] == 'answer') {
        _webrtcService.handleRemoteDescription('answer', message['sdp']);
      }
    } else if (message['type'] == 'webrtc_ice') {
      _webrtcService.handleIceCandidate(message);
    } else if (message['type'] == 'transcript') {
      if (mounted) {
        setState(() {
          _transcripts.add(message);
          // keep only last 10
          if (_transcripts.length > 10) {
            _transcripts.removeAt(0);
          }
        });
      }
    } else if (message['type'] == 'user_left') {
      if (mounted) {
        setState(() {
          _isRemoteConnected = false;
          _remoteRenderer.srcObject = null;
        });
      }
    } else if (message['type'] == 'join') {
      // If someone else joins the room, we should re-offer to establish connection
      if (message['user_id'] != widget.userId && widget.role == 'hr') {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _webrtcService.createOffer(widget.roomId, widget.userId);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    _sttService.stopListening();
    _signalingService.disconnect();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _webrtcService.toggleMicrophone(_isMuted);

    if (_isMuted) {
      _sttService.stopListening();
    } else {
      _sttService.startListening(widget.roomId, widget.userId, widget.role);
    }
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _webrtcService.toggleCamera(_isVideoOff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Interview Room'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Remote Video (Full Screen)
              if (_isRemoteConnected)
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                const Center(
                  child: Text(
                    'Waiting for other participant...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              // Local Video (PiP)
              Positioned(
                top: _pipTop,
                left: _pipLeft,
                right: _pipRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final maxTop = constraints.maxHeight - 160;
                      final maxLeft = constraints.maxWidth - 120;

                      _pipTop = (_pipTop ?? 20) + details.delta.dy;
                      _pipTop = _pipTop!.clamp(0.0, maxTop);

                      if (_pipLeft != null) {
                        _pipLeft = _pipLeft! + details.delta.dx;
                        _pipLeft = _pipLeft!.clamp(0.0, maxLeft);
                      } else {
                        if (_pipRight != null) {
                          _pipLeft = constraints.maxWidth - 120 - _pipRight!;
                          _pipRight = null;
                        }
                        _pipLeft = (_pipLeft ?? 0) + details.delta.dx;
                        _pipLeft = _pipLeft!.clamp(0.0, maxLeft);
                      }
                    });
                  },
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              ),

              // Subtitles/Transcripts
              if (_transcripts.isNotEmpty)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      itemCount: _transcripts.length,
                      itemBuilder: (context, index) {
                        final msg = _transcripts[index];
                        final isMe = msg['speaker_id'] == widget.userId;
                        final roleText = isMe
                            ? 'You'
                            : (msg['role'] == 'hr' ? 'HR' : 'Candidate');
                        final color = isMe
                            ? Colors.blue[300]
                            : Colors.green[300];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$roleText: ',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: msg['text'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Controls
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: _isMuted ? Colors.red : Colors.white24,
                      child: IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                      ),
                    ),
                    const SizedBox(width: 20),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: _isVideoOff
                          ? Colors.red
                          : Colors.white24,
                      child: IconButton(
                        icon: Icon(
                          _isVideoOff ? Icons.videocam_off : Icons.videocam,
                          color: Colors.white,
                        ),
                        onPressed: _toggleVideo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
