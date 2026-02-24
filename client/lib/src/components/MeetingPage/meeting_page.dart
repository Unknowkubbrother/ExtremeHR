import 'package:flutter/material.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/MeetingPage/video_meeting.dart';
import 'package:client/src/components/MeetingPage/chat_meeting.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/components/HomePage/main_navigation_page.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key, required this.id});

  final String id;

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Interview - ${widget.id}")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            VideoMeeting(),
            SizedBox(height: 16),
            Expanded(
              child: CardContent(
                header: Row(
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 70.0),
                    child: ChatMeeting(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerousColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainNavigationPage(state: 2),
                ),
              );
            },
            child: Text(
              "Leave",
              style: TextStyle(
                color: AppColors.background,
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
