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
  double? _pipTop = 10;
  double? _pipRight = 7;
  double? _pipLeft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 400,
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
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.people,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: _pipTop,
              left: _pipLeft,
              right: _pipRight,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final maxTop = 400.0 - 100;
                    final maxLeft = constraints.maxWidth - 100;

                    _pipTop = (_pipTop ?? 10) + details.delta.dy;
                    _pipTop = _pipTop!.clamp(0.0, maxTop);

                    if (_pipLeft != null) {
                      _pipLeft = _pipLeft! + details.delta.dx;
                      _pipLeft = _pipLeft!.clamp(0.0, maxLeft);
                    } else {
                      if (_pipRight != null) {
                        _pipLeft = constraints.maxWidth - 100 - _pipRight!;
                        _pipRight = null;
                      }
                      _pipLeft = (_pipLeft ?? 0) + details.delta.dx;
                      _pipLeft = _pipLeft!.clamp(0.0, maxLeft);
                    }
                  });
                },
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
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
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
            ),
          ],
        );
      },
    );
  }
}
