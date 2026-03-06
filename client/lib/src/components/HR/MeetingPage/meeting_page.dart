import 'package:client/src/components/shared/confirm.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:flutter/material.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/MeetingPage/video_meeting.dart';
import 'package:client/src/components/MeetingPage/chat_meeting.dart';
import 'package:client/src/components/ResumePage/card_content.dart';

class HRMeetingPage extends StatefulWidget {
  const HRMeetingPage({super.key, required this.id});

  final String id;

  @override
  State<HRMeetingPage> createState() => _HRMeetingPageState();
}

class _HRMeetingPageState extends State<HRMeetingPage> {
  bool _isMicOn = false;
  bool _isCameraOn = true;

  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authService = AuthStorage();

  Future<void> _endInterview() async {
    final token = await _authService.getToken();
    if (token != null) {
      await _interviewService.endInterview(token, widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Interview")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            VideoMeeting(isCameraOn: _isCameraOn),
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
                child: Expanded(child: ChatMeeting(isMicOn: _isMicOn)),
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
              onPressed: () => setState(() => _isMicOn = !_isMicOn),
            ),
            const SizedBox(width: 8),
            // Camera Button
            _buildControlButton(
              icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
              color: _isCameraOn ? AppColors.primary : Colors.grey,
              onPressed: () => setState(() => _isCameraOn = !_isCameraOn),
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
                    Navigator.pop(context);
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
