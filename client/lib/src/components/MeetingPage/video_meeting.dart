import 'package:flutter/material.dart';

class VideoMeeting extends StatefulWidget {
  final bool isCameraOn;
  const VideoMeeting({super.key, required this.isCameraOn});

  @override
  State<VideoMeeting> createState() => _VideoMeetingState();
}

class _VideoMeetingState extends State<VideoMeeting> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: const Center(
            child: Icon(Icons.people, size: 100, color: Colors.white),
          ),
        ),
        Positioned(
          top: 10,
          right: 7,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.isCameraOn
                ? Container(
                    key: const ValueKey('camera_on'),
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade800,
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  )
                : Container(
                    key: const ValueKey('camera_off'),
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black54,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.videocam_off,
                        size: 30,
                        color: Colors.white54,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
