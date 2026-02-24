import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:client/src/components/ResumePage/card_content.dart';

class JobDetailPage extends StatelessWidget {
  const JobDetailPage({super.key});

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
                  "Job Title",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSizes.title,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Company Name",
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
                      "Job Location",
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
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: _buildJobTag([
                          "Tasssssssssssssssssssssssssssssg1",
                          "Tag2",
                          "Tag3",
                        ]),
                      ),
                      _buildJobDescription("Job Description..."),
                      _buildResponsibilities([
                        "Responsibility 1",
                        "Responsibility 2",
                        "Responsibility 3",
                      ]),
                      _buildQualifications([
                        "Qualification 1",
                        "Qualification 2",
                        "Qualification 3",
                      ]),
                      _buildSkills(["Skill 1", "Skill 2", "Skill 3"]),
                      Text(
                        "post on ...",
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
            return Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  responsibility,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textPrimaryTo,
                  ),
                ),
              ],
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
            return Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  qualification,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.textPrimaryTo,
                  ),
                ),
              ],
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
