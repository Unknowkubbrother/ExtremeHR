import 'package:client/src/components/HR/interview/candidate_resume_page.dart';
import 'package:client/src/components/InterviewPage/interview_card.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/hr_candidate_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:flutter/material.dart';

class CandidateListPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const CandidateListPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<CandidateListPage> createState() => _CandidateListPageState();
}

class _CandidateListPageState extends State<CandidateListPage> {
  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authService = AuthStorage();
  List<HRCandidateModel> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final candidates = await _interviewService.getJobCandidates(
          token,
          widget.jobId,
        );
        if (mounted) {
          setState(() {
            _candidates = candidates;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading candidates: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        title: Text(
          "Candidates for ${widget.jobTitle}",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Candidates: ${_candidates.length}",
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading && _candidates.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCandidates,
                child: _buildList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_candidates.isEmpty) {
      return const Center(child: Text("No candidates found."));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _candidates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final candidate = _candidates[index];
        return InterviewCard(
          icon: Icons.person_outline,
          id: candidate.id,
          state: candidate.state,
          isHR: true,
          onRefresh: _loadCandidates,
          action: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CandidateResumePage(
                  candidateId: candidate.candidateId,
                  interviewId: candidate.id,
                  candidateName: candidate.candidateName,
                  initialStatus: candidate.state,
                ),
              ),
            );
            _loadCandidates();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.candidateName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppFontSizes.body,
                  color: AppColors.textPrimaryTo,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Applied on ${candidate.createdAt.toString().split(' ')[0]}",
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
