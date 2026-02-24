import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:client/src/models/jobDetail_model.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final storage = AuthStorage();
  final jobServices = JobServices();
  JobDetail? jobs;

  Future<void> getJobDetail() async {
    try {
      final token = await storage.getToken();

      final response = await jobServices.getJobDetail(
        token!,
        int.parse(widget.jobId),
      );

      setState(() {
        jobs = response;
      });

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load job detail1')),
      );
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getJobDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        title: Text(
          "Job Detail",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobs?.title ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSizes.title,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  jobs?.company ?? "",
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    Text(
                      jobs?.location ?? "",
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildJobTag(
                          jobs != null
                              ? [
                                  "\$${jobs!.minSalary} - \$${jobs!.maxSalary}",
                                  "${jobs!.minAge}-${jobs!.maxAge} years old",
                                  "${jobs!.headcount} Positions",
                                ]
                              : [],
                        ),
                      ),
                      if (jobs?.description != null &&
                          jobs!.description.isNotEmpty)
                        _buildJobDescription(jobs!.description),
                      if (jobs?.responsibilities != null &&
                          jobs!.responsibilities.isNotEmpty)
                        _buildResponsibilities(jobs!.responsibilities),
                      if (jobs?.qualifications != null &&
                          jobs!.qualifications.isNotEmpty)
                        _buildQualifications(jobs!.qualifications),
                      if (jobs?.skills != null && jobs!.skills.isNotEmpty)
                        _buildSkills(jobs!.skills),
                      if (jobs?.postedAt != null)
                        Text(
                          "posted on ${jobs!.postedAt.toString().split(' ')[0]}",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      SizedBox(height: 128),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {},
            child: Text(
              "Apply Now",
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
      child: Column(
        children: [
          Text(
            description,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: AppFontSizes.body,
              color: AppColors.textPrimaryTo,
            ),
          ),
        ],
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
                  SizedBox(width: 8),
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
                  SizedBox(width: 8),
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
