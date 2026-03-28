import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/candidate_compare_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:flutter/material.dart';
import 'compare_one_on_one_page.dart';
import 'package:client/src/models/status_enum.dart';
import 'package:client/src/components/HR/interview/candidate_resume_page.dart';

class CompareCandidatesPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const CompareCandidatesPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<CompareCandidatesPage> createState() => _CompareCandidatesPageState();
}

class _CompareCandidatesPageState extends State<CompareCandidatesPage> {
  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authService = AuthStorage();
  List<CandidateCompareModel> _candidates = [];
  bool _isLoading = true;
  String _sortBy = 'Total Score';

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final data = await _interviewService.getJobComparisonData(
          token,
          widget.jobId,
        );
        setState(() {
          _candidates = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading comparison data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comparison data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort logic
    final sortedCandidates = List<CandidateCompareModel>.from(_candidates);
    sortedCandidates.sort((a, b) {
      if (_sortBy == 'Experience')
        return b.summary.experienceScore.compareTo(a.summary.experienceScore);
      if (_sortBy == 'Communication')
        return b.summary.communicationScore.compareTo(
          a.summary.communicationScore,
        );
      if (_sortBy == 'Technical')
        return b.summary.technicalScore.compareTo(a.summary.technicalScore);
      return b.summary.totalScore.compareTo(
        a.summary.totalScore,
      ); // Default Total Score
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        title: Text(
          "Compare candidates",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (_candidates.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: "1-on-1 Compare",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CompareOneOnOneMockPage(candidates: _candidates),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _candidates.isEmpty
          ? const Center(child: Text("No 'viewed' candidates to compare."))
          : Column(
              children: [
                // Filter / Sort Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sort By:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSizes.body,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            items:
                                [
                                      'Total Score',
                                      'Experience',
                                      'Communication',
                                      'Technical',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortBy = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: sortedCandidates.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final cand = sortedCandidates[index];
                      return _buildCandidateCard(cand);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCandidateCard(CandidateCompareModel cand) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ), // Stronger border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Navigate to resume page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CandidateResumePage(
                  candidateId: cand.candidateId,
                  interviewId: cand.interviewId,
                  candidateName: cand.candidateName,
                  initialStatus: Status.view,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cand.candidateName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSizes.subtitle,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Score: ${(cand.summary.totalScore * 10).toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Scores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreItem("Exp.", cand.summary.experienceScore),
                    _buildScoreItem("Comm.", cand.summary.communicationScore),
                    _buildScoreItem("Tech.", cand.summary.technicalScore),
                  ],
                ),
                const SizedBox(height: 16),
                // Strengths & Weaknesses
                if (cand.summary.strengths.isNotEmpty) ...[
                  Text(
                    "Strengths",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  ...cand.summary.strengths
                      .take(2)
                      .map(
                        (s) => Text(
                          "• ${s.title}",
                          style: const TextStyle(
                            fontSize: AppFontSizes.caption,
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                ],
                if (cand.summary.weaknesses.isNotEmpty) ...[
                  Text(
                    "Weaknesses",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  ...cand.summary.weaknesses
                      .take(2)
                      .map(
                        (w) => Text(
                          "• ${w.title}",
                          style: const TextStyle(
                            fontSize: AppFontSizes.caption,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, double score) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSizes.caption,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (score * 10).toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppFontSizes.body,
          ),
        ),
      ],
    );
  }
}
