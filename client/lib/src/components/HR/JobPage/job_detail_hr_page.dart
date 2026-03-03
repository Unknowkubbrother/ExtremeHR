import 'package:client/src/components/HR/JobPage/job_edit_page.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/jobDetail_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:flutter/material.dart';

// ใช้เหมือน Candidate
import 'package:client/src/components/ResumePage/card_content.dart';

class JobDetailHRPage extends StatefulWidget {
  final int jobId;

  const JobDetailHRPage({super.key, required this.jobId});

  @override
  State<JobDetailHRPage> createState() => _JobDetailHRPageState();
}

class _JobDetailHRPageState extends State<JobDetailHRPage> {
  final JobServices _jobService = JobServices();
  final AuthStorage _authStorage = AuthStorage();

  JobDetail? _job;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        final job = await _jobService.getJobDetail(token, widget.jobId);
        if (!mounted) return;
        setState(() => _job = job);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _goEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobEditPage(job: _job)),
    );
    if (result != null) _loadJob();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_job == null) {
      return const Scaffold(body: Center(child: Text("Job not found")));
    }

    final job = _job!;
    final tags = [
      "\$${job.minSalary} - \$${job.maxSalary}",
      "${job.minAge}-${job.maxAge} years old",
      "${job.headcount} Positions",
      ...job.jobFields,
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          "Job Detail",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ✅ ทำเป็น Stack แบบต้นฉบับ
      body: Stack(
        children: [
          // ===== Scroll content =====
          SingleChildScrollView(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header (พื้น primary)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppFontSizes.title,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body (พื้นขาวโค้งบน)
                  Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _buildJobTag(tags),
                          ),

                          if (job.description.isNotEmpty)
                            _buildJobDescription(job.description),

                          if (job.responsibilities.isNotEmpty)
                            _buildResponsibilities(job.responsibilities),

                          if (job.qualifications.isNotEmpty)
                            _buildQualifications(job.qualifications),

                          if (job.skills.isNotEmpty) _buildSkills(job.skills),

                          Text(
                            "posted on ${job.postedAt.toString().split(' ')[0]}",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),

                          // ✅ เผื่อพื้นที่ให้ปุ่มล่าง (แบบต้นฉบับ)
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Bottom overlay button (เหมือนต้นฉบับ) =====
          Align(
            alignment: Alignment.bottomCenter,
            child: HeroMode(
              enabled: false, // ✅ กันปุ่มเด้ง/หมุนจาก hero
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                    onPressed: _goEdit,
                    child: Text(
                      "Edit Job",
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== UI helpers (เหมือน Candidate) =====

  Widget _buildJobTag(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: AppFontSizes.small,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJobDescription(String description) {
    return CardContent(
      header: Text(
        "Job Description",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: AppFontSizes.body,
          color: AppColors.textPrimaryTo,
        ),
      ),
    );
  }

  Widget _buildResponsibilities(List<String> responsibilities) {
    return CardContent(
      header: Text(
        "Responsibilities",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Column(
        children: [
          ...responsibilities.map((responsibility) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      responsibility,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.textPrimaryTo,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQualifications(List<String> qualifications) {
    return CardContent(
      header: Text(
        "Qualifications",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Column(
        children: [
          ...qualifications.map((qualification) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qualification,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.textPrimaryTo,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkills(List<String> skills) {
    return CardContent(
      header: Text(
        "Skills",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              skill,
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
