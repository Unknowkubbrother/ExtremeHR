import 'package:flutter/material.dart';

class VideoMeeting extends StatefulWidget {
  const VideoMeeting({super.key});

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
          child: Center(
            child: Icon(Icons.people, size: 100, color: Colors.white),
          ),
        ),
        Positioned(
          top: 10,
          right: 7,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey,
            ),
            child: Center(
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
