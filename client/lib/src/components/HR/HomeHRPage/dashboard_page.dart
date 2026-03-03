import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/models/job_hr_model.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:flutter/material.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final AuthStorage _authService = AuthStorage();
  final JobServices _jobService = JobServices();

  bool _isLoading = true;
  JobStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final stats = await _jobService.getHRStats(token);
        if (mounted) {
          setState(() {
            _stats = stats;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard(
                title: "Active Jobs",
                value: _isLoading
                    ? "..."
                    : _stats?.activeJobs.toString() ?? "0",
                icon: Icons.work_outline_rounded,
                color: Colors.lightBlue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: "Interviews",
                value: _isLoading
                    ? "..."
                    : _stats?.interviews.toString() ?? "0",
                icon: Icons.people_outline_rounded,
                color: Colors.amber,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: "Approve",
                value: _isLoading ? "..." : _stats?.approved.toString() ?? "0",
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: CardContent(
        header: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
