import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoMeeting extends StatefulWidget {
  final bool isCameraOn;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final bool isRemoteConnected;

  const VideoMeeting({
    super.key,
    required this.isCameraOn,
    required this.localRenderer,
    required this.remoteRenderer,
    required this.isRemoteConnected,
  });

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
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.isRemoteConnected
                ? RTCVideoView(
                    widget.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : const Center(
                    child: Icon(Icons.people, size: 100, color: Colors.white),
                  ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: RTCVideoView(
                        widget.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
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
