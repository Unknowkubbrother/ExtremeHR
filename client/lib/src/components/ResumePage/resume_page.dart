import 'package:client/src/components/ResumePage/personal_info_card.dart';
import 'package:client/src/components/ResumePage/skills_card.dart';
import 'package:client/src/components/ResumePage/education_card.dart';
import 'package:client/src/components/ResumePage/exprience_card.dart';
import 'package:client/src/components/ResumePage/project_card.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/personal_info_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/resume_services.dart';
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
  final GlobalKey<ProjectCardState> _projectKey = GlobalKey<ProjectCardState>();

  final ResumeService _resumeService = ResumeService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isPersonalInfoEditing = false;
  bool _isLoading = false;
  PersonalInformation _personalData = PersonalInformation(
    fullName: "",
    age: null,
    phone: null,
    email: null,
    address: null,
    skills: [],
    education: [],
    experience: [],
    projects: [],
  );

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  void _onEditPressed() {
    setState(() {
      _isPersonalInfoEditing = true;
    });
  }

  void _onCancelPressed() {
    _personalInfoKey.currentState?.resetData();
    _skillsKey.currentState?.resetData();
    _educationKey.currentState?.resetData();
    _experienceKey.currentState?.resetData();
    _projectKey.currentState?.resetData();
    setState(() {
      _isPersonalInfoEditing = false;
    });
  }

  void _onSavePressed() {
    final updatedInfo = _personalInfoKey.currentState?.getUpdatedData();
    final updatedSkills = _skillsKey.currentState?.getUpdatedSkills();
    final updatedEducation = _educationKey.currentState?.getUpdatedEducation();
    final updatedExperience = _experienceKey.currentState
        ?.getUpdatedExperience();
    final updatedProjects = _projectKey.currentState?.getUpdatedProjects();

    if (updatedInfo != null &&
        updatedSkills != null &&
        updatedEducation != null &&
        updatedExperience != null &&
        updatedProjects != null) {
      final newData = updatedInfo.copyWith(
        skills: updatedSkills,
        education: updatedEducation,
        experience: updatedExperience,
        projects: updatedProjects,
      );
      _saveResume(newData);
    }
  }

  Future<void> _loadResume() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        final data = await _resumeService.getMyResume(token);
        if (!mounted) return;
        setState(() {
          _personalData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading resume: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveResume(PersonalInformation data) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        final updatedData = await _resumeService.saveResume(token, data);
        if (!mounted) return;
        setState(() {
          _personalData = updatedData;
          _isPersonalInfoEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving resume: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  "My Resume",
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isPersonalInfoEditing)
                  ElevatedButton(
                    onPressed: _onEditPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: const Text("Edit Resume"),
                  )
                else
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _onSavePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        child: Text(_isLoading ? "Saving..." : "Save"),
                      ),
                      if (!_isLoading) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _onCancelPressed,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ],
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
            ProjectCard(
              key: _projectKey,
              projects: _personalData.projects,
              isEditing: _isPersonalInfoEditing,
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
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
