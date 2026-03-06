import 'package:client/src/components/HR/MeetingPage/meeting_page.dart';
import 'package:client/src/components/MeetingPage/meeting_page.dart';
import 'package:client/src/components/SummaryPage/summary_page.dart';
import 'package:client/src/components/shared/status_badge.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/models/status_enum.dart';
import 'package:flutter/material.dart';

class InterviewCard extends StatelessWidget {
  const InterviewCard({
    super.key,
    required this.icon,
    required this.child,
    required this.action,
    required this.state,
    required this.id,
    this.isHR = false,
    this.onRefresh,
  });

  final Status state;
  final String id;
  final IconData icon;
  final Widget child;
  final VoidCallback action;
  final bool isHR;
  final VoidCallback? onRefresh;

  void _handleBadgeTap(BuildContext context) async {
    if (state == Status.interview) {
      if (isHR) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HRMeetingPage(id: id)),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MeetingPage(id: id)),
        );
      }
      if (onRefresh != null) onRefresh!();
    } else if (state == Status.view || state == Status.accepted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SummaryPage()),
      );
      if (onRefresh != null) onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            StatusBadge(
              status: state,
              onTap:
                  (state == Status.interview ||
                      state == Status.view ||
                      state == Status.accepted)
                  ? () => _handleBadgeTap(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
