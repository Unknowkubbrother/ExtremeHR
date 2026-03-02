import 'package:client/src/models/job_hr_model.dart';
import 'package:client/src/components/HomePage/card_list.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';

class JobListHR extends StatefulWidget {
  const JobListHR({super.key});

  @override
  State<JobListHR> createState() => _JobListHRState();
}

class _JobListHRState extends State<JobListHR> {
  final List<JobHR> _mockJobs = [
    JobHR(
      id: 1,
      title: "Senior React Developer",
      company: "Tech Solutions Inc.",
      candidateCount: 12,
    ),
    JobHR(
      id: 2,
      title: "UI/UX Designer",
      company: "Creative Agency",
      candidateCount: 5,
    ),
    JobHR(
      id: 3,
      title: "Backend Engineer (Python)",
      company: "Data Systems Corp.",
      candidateCount: 8,
    ),
    JobHR(
      id: 4,
      title: "Product Manager",
      company: "Growth Startup",
      candidateCount: 20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _mockJobs.length,
        itemBuilder: (context, index) {
          final job = _mockJobs[index];
          return CardList(
            icon: Icons.work_outline,
            action: () {
              debugPrint("Job Card Clicked: ${job.title}");
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
      ),
    );
  }
}
