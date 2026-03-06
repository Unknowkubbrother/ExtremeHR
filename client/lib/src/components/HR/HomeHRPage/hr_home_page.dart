import 'package:client/src/components/HR/HomeHRPage/dashboard_page.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/job_hr_model.dart';
import 'package:client/src/services/job_services.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:flutter/material.dart';

class HRHomePage extends StatefulWidget {
  const HRHomePage({super.key});

  @override
  State<HRHomePage> createState() => _HRHomePageState();
}

class _HRHomePageState extends State<HRHomePage> {
  final JobServices _jobService = JobServices();
  List<RecentApplyResponse> _recentApply = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentApply();
  }

  Future<void> _loadRecentApply() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthStorage().getToken();
      if (token != null) {
        final recentApply = await _jobService.getHRRecentApply(token);
        if (mounted) {
          setState(() {
            _recentApply = recentApply;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading recent apply: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const DashBoard(),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CardContent(
              header: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Recent activity",
                    style: TextStyle(
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryTo,
                    ),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _recentApply.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No recent activity",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _recentApply.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final recentApply = _recentApply[index];
                        return _ActivityRow(recentApply: recentApply);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final RecentApplyResponse recentApply;
  const _ActivityRow({required this.recentApply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            radius: 18,
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recentApply.candidateName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  recentApply.title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            recentApply.dateAt.toString().split(' ')[0],
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
