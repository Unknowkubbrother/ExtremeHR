import 'package:client/src/models/status_enum.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final Status status;
  final VoidCallback? onTap;

  const StatusBadge({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case Status.waiting:
        color = Colors.grey;
        label = "Waiting";
        break;
      case Status.interview:
        color = Colors.green;
        label = "Interview";
        break;
      case Status.reject:
        color = Colors.red;
        label = "Rejected";
        break;
      case Status.view:
        color = Colors.blue;
        label = "Viewed";
        break;
      case Status.accepted:
        color = Colors.green;
        label = "Accepted";
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: onTap != null
            ? Border.all(color: color.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 10, color: color),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }
}
