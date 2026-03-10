import 'package:client/src/components/shared/confirm.dart';
import 'package:client/src/models/status_enum.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:client/src/services/resume_services.dart';
import 'package:client/src/models/personal_info_model.dart';
import 'package:flutter/material.dart';

class CandidateResumePage extends StatefulWidget {
  final String candidateId;
  final String interviewId;
  final String candidateName;
  final Status initialStatus;

  const CandidateResumePage({
    super.key,
    required this.candidateId,
    required this.interviewId,
    required this.candidateName,
    required this.initialStatus,
  });

  @override
  State<CandidateResumePage> createState() => _CandidateResumePageState();
}

class _CandidateResumePageState extends State<CandidateResumePage> {
  final ResumeService _resumeService = ResumeService();
  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authService = AuthStorage();

  final ConfirmDialog _rejectDialog = ConfirmDialog(
    title: "Reject this candidate?",
    content: "This action cannot be undone.",
    confirmText: "Reject",
    cancelText: "Cancel",
    confirmColor: Colors.red,
    cancelColor: AppColors.textPrimaryTo,
  );

  final ConfirmDialog _interviewDialog = ConfirmDialog(
    title: "Interview this candidate?",
    content: "This action cannot be undone.",
    confirmText: "Interview",
    cancelText: "Cancel",
    confirmColor: Colors.green,
    cancelColor: AppColors.textPrimaryTo,
  );

  final ConfirmDialog _acceptDialog = ConfirmDialog(
    title: "Accept this candidate?",
    content: "This candidate will move to the accepted stage.",
    confirmText: "Accept",
    cancelText: "Cancel",
    confirmColor: Colors.green,
    cancelColor: AppColors.textPrimaryTo,
  );

  PersonalInformation? _resume;
  bool _isLoading = true;
  bool _isUpdating = false;
  late Status _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _loadResume();
  }

  Future<void> _loadResume() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final resume = await _resumeService.getCandidateResume(
          token,
          int.parse(widget.candidateId),
        );
        if (mounted) {
          setState(() {
            _resume = resume;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading candidate resume: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reject() async {
    final result = await _rejectDialog.show(context);
    if (result != true) return;

    setState(() => _isUpdating = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        await _interviewService.rejectInterview(token, widget.interviewId);
        if (mounted) {
          setState(() => _currentStatus = Status.reject);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Candidate rejected')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reject candidate')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _interview() async {
    final result = await _interviewDialog.show(context);
    if (result != true) return;

    setState(() => _isUpdating = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        await _interviewService.interviewCandidate(token, widget.interviewId);
        if (mounted) {
          setState(() => _currentStatus = Status.interview);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Interview scheduled')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to schedule meeting')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _accept() async {
    final result = await _acceptDialog.show(context);
    if (result != true) return;

    setState(() => _isUpdating = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        await _interviewService.acceptInterview(token, widget.interviewId);
        if (mounted) {
          setState(() => _currentStatus = Status.accepted);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Candidate accepted')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWaitingStatus = _currentStatus == Status.waiting;
    final isViewedStatus = _currentStatus == Status.view;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        title: Text(
          widget.candidateName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16),
        //     child: StatusBadge(status: _currentStatus),
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_resume == null)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No resume uploaded by candidate."),
                              )
                            else ...[
                              _buildPersonalInfo(),
                              if (_resume!.skills.isNotEmpty) _buildSkills(),
                              if (_resume!.education.isNotEmpty)
                                _buildEducation(),
                              if (_resume!.experience.isNotEmpty)
                                _buildExperience(),
                            ],
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (!isWaitingStatus && !isViewedStatus)
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating || _resume == null
                          ? null
                          : (isWaitingStatus ? _interview : _accept),
                      child: Text(
                        isWaitingStatus ? "Interview" : "Accept",
                        style: TextStyle(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating || _resume == null
                          ? null
                          : () => _reject(),
                      child: const Text(
                        "Reject",
                        style: TextStyle(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalInfo() {
    return CardContent(
      header: Text(
        "Personal Information",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Full Name", _resume!.fullName),
          _infoRow("Age", _resume!.age.toString()),
          _infoRow("Email", _resume!.email ?? '-'),
          _infoRow("Phone", _resume!.phone ?? '-'),
          _infoRow("Address", _resume!.address ?? '-'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.textPrimaryTo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills() {
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
        children: _resume!.skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(skill, style: TextStyle(color: AppColors.primary)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEducation() {
    return CardContent(
      header: Text(
        "Education",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Column(
        children: _resume!.education.map((edu) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.institution,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSizes.body,
                  ),
                ),
                Text(
                  "${edu.degree} in ${edu.major}",
                  style: TextStyle(color: AppColors.textPrimaryTo),
                ),
                Text(
                  "GPAX: ${edu.gpax}",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  "${edu.startMonth ?? ''} ${edu.startYear ?? ''} - ${edu.endMonth ?? ''} ${edu.endYear ?? ''}",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExperience() {
    return CardContent(
      header: Text(
        "Experience",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.subtitle,
          color: AppColors.primary,
        ),
      ),
      child: Column(
        children: _resume!.experience.map((exp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.role ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSizes.body,
                  ),
                ),
                Text(
                  exp.company,
                  style: TextStyle(color: AppColors.textPrimaryTo),
                ),
                Text(
                  "${exp.startMonth ?? ''} ${exp.startYear ?? ''} - ${exp.endMonth ?? ''} ${exp.endYear ?? ''}",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exp.description ?? '',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
