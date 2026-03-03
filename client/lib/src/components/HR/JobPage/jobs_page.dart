import 'package:client/src/components/HR/JobPage/job_detail_hr_page.dart';
import 'package:client/src/components/HR/JobPage/job_edit_page.dart';
import 'package:client/src/components/HomePage/card_list.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/job_hr_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:flutter/material.dart';

class JobsHRPage extends StatefulWidget {
  const JobsHRPage({super.key});

  @override
  State<JobsHRPage> createState() => _JobsHRPageState();
}

class _JobsHRPageState extends State<JobsHRPage> {
  final JobServices _jobService = JobServices();
  final AuthStorage _authService = AuthStorage();
  List<JobHR> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final jobs = await _jobService.getJobsByHR(token);
        if (mounted) {
          setState(() {
            _jobs = jobs;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading jobs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Jobs (${_jobs.length})",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobEditPage(),
                    ),
                  );
                  if (result != null) _loadJobs();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
                child: const Text("Add Job"),
              ),
            ],
          ),
        ),
        if (_isLoading && _jobs.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: RefreshIndicator(onRefresh: _loadJobs, child: _buildList()),
          ),
      ],
    );
  }

  Widget _buildList() {
    if (_jobs.isEmpty) {
      return const Center(child: Text("No jobs posted yet."));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _jobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return CardList(
          icon: Icons.work_outline,
          action: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailHRPage(jobId: job.id),
              ),
            );
            _loadJobs();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppFontSizes.body,
                ),
              ),
              Text(
                job.company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: AppFontSizes.caption),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      "${job.candidateCount} candidates",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
