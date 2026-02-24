import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/components/MeetingPage/meeting_page.dart';
import 'package:flutter/material.dart';

class InterviewCard extends StatelessWidget {
  const InterviewCard({
    super.key,
    required this.icon,
    required this.child,
    required this.action,
    required this.state,
    required this.id,
  });

  final int state;
  final String id;
  final IconData icon;
  final Widget child;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    Map<int, Widget> stateWidget = {
      0: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MeetingPage(id: id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 217, 218, 222),
          foregroundColor: Colors.white,
        ),
        child: Text("Waiting", style: TextStyle(color: Colors.black)),
      ),
      1: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MeetingPage(id: id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 23, 157, 5),
          foregroundColor: Colors.white,
        ),
        child: Text("Join Meeting", style: TextStyle(color: Colors.white)),
      ),
      2: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MeetingPage(id: id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 252, 208, 208),
          foregroundColor: Colors.red,
        ),
        child: Text("Reject", style: TextStyle(color: Colors.red)),
      ),
      3: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MeetingPage(id: id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        child: Text("View ", style: TextStyle(color: Colors.white)),
      ),
    };

    return GestureDetector(
      onTap: action,
      child: CardContent(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: child),
                ],
              ),
            ),
            const SizedBox(width: 16),
            stateWidget[state] ?? const Text("Unknown"),
            // Icon(Icons.navigate_next, color: AppColors.primary, size: 36),
          ],
        ),
      ),
    );
  }
}
