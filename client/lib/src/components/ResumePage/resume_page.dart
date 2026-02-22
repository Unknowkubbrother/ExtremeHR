import 'package:client/src/components/ResumePage/personal_info_card.dart';
import 'package:client/src/components/ResumePage/skills_card.dart';
import 'package:client/src/components/ResumePage/education_card.dart';
import 'package:client/src/components/ResumePage/exprience_card.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/personal_info_model.dart';
import 'package:flutter/material.dart';

class ResumePage extends StatefulWidget {
  const ResumePage({super.key});

  @override
  State<ResumePage> createState() => _ResumePageState();
}

class _ResumePageState extends State<ResumePage> {
  final GlobalKey<PersonalInfoCardState> _personalInfoKey =
      GlobalKey<PersonalInfoCardState>();
  final GlobalKey<SkillsCardState> _skillsKey = GlobalKey<SkillsCardState>();
  final GlobalKey<EducationCardState> _educationKey =
      GlobalKey<EducationCardState>();
  final GlobalKey<ExperienceCardState> _experienceKey =
      GlobalKey<ExperienceCardState>();
  bool _isPersonalInfoEditing = false;
  PersonalInformation _personalData = PersonalInformation(
    fullName: "",
    age: "",
    phone: "",
    email: "",
    address: "",
    skills: [],
    education: [],
    experience: [],
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Upload your resume to get started",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.normal,
                  color: AppColors.inputTextColor,
                ),
              ),
            ),
            _buildUploadButton(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Profile",
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isPersonalInfoEditing)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isPersonalInfoEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: const Text("Edit Profile"),
                  )
                else
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final updatedInfo = _personalInfoKey.currentState
                              ?.getUpdatedData();
                          final updatedSkills = _skillsKey.currentState
                              ?.getUpdatedSkills();
                          final updatedEducation = _educationKey.currentState
                              ?.getUpdatedEducation();
                          final updatedExperience = _experienceKey.currentState
                              ?.getUpdatedExperience();

                          if (updatedInfo != null &&
                              updatedSkills != null &&
                              updatedEducation != null &&
                              updatedExperience != null) {
                            setState(() {
                              _personalData = updatedInfo.copyWith(
                                skills: updatedSkills,
                                education: updatedEducation,
                                experience: updatedExperience,
                              );
                              _isPersonalInfoEditing = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        child: const Text("บันทึก"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isPersonalInfoEditing = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("ยกเลิก"),
                      ),
                    ],
                  ),
              ],
            ),
            PersonalInfoCard(
              key: _personalInfoKey,
              data: _personalData,
              isEditing: _isPersonalInfoEditing,
            ),
            SkillsCard(
              key: _skillsKey,
              skills: _personalData.skills,
              isEditing: _isPersonalInfoEditing,
            ),
            EducationCard(
              key: _educationKey,
              education: _personalData.education,
              isEditing: _isPersonalInfoEditing,
            ),
            ExperienceCard(
              key: _experienceKey,
              experience: _personalData.experience,
              isEditing: _isPersonalInfoEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement resume upload logic
        print("Upload button tapped");
      },
      child: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(Icons.upload_file, size: 48, color: AppColors.textPrimary),
            Column(
              children: [
                Text(
                  "Upload your resume",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Resume/CV PDF 10MB",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSizes.small,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
