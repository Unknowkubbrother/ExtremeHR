import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/interview_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:flutter/material.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({
    super.key,
    required this.interviewId,
    required this.canGenerate,
  });

  final String interviewId;
  final bool canGenerate;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authStorage = AuthStorage();

  InterviewSummary? _summary;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final summary = await _interviewService.getInterviewSummary(
        token,
        widget.interviewId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summary = null;
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final summary = await _interviewService.generateInterviewSummary(
        token,
        widget.interviewId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้าง summary สำเร็จ')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimaryTo,
        title: const Text('Interview Summary'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_summary == null) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreCard(_summary!),
        const SizedBox(height: 16),
        _buildMetaCard(_summary!),
        const SizedBox(height: 16),
        _buildPointCard(
          title: 'Strengths',
          icon: Icons.check_circle_outline_outlined,
          color: AppColors.positiveColor,
          points: _summary!.strengths,
        ),
        const SizedBox(height: 16),
        _buildPointCard(
          title: 'Weaknesses',
          icon: Icons.cancel_outlined,
          color: AppColors.dangerousColor,
          points: _summary!.weaknesses,
        ),
        const SizedBox(height: 16),
        _buildEvidenceCard(_summary!),
        const SizedBox(height: 16),
        _buildRedFlagCard(_summary!),
        const SizedBox(height: 16),
        _buildTextCard(
          title: 'Summary',
          icon: Icons.summarize_outlined,
          color: AppColors.primary,
          content: _summary!.suggestionSummary,
        ),
        const SizedBox(height: 16),
        _buildTextCard(
          title: 'Next Step',
          icon: Icons.arrow_forward_outlined,
          color: AppColors.primary,
          content: _summary!.nextStep,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'ยังไม่มี summary สำหรับ interview นี้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.canGenerate) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Summary',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(InterviewSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Score',
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              fontSize: AppFontSizes.body,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.totalScore.toStringAsFixed(2),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildScoreChip('Experience', summary.experienceScore),
              _buildScoreChip('Communication', summary.communicationScore),
              _buildScoreChip('Technical', summary.technicalScore),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              fontSize: AppFontSizes.caption,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(InterviewSummary summary) {
    return CardContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaRow('Recommendation', _mapRecommendation(summary.recommendation)),
          const SizedBox(height: 12),
          _buildMetaRow('Confidence', summary.confidence.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryTo,
          ),
        ),
      ],
    );
  }

  Widget _buildPointCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<InterviewSummaryPoint> points,
  }) {
    return CardContent(
      header: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: color,
            ),
          ),
        ],
      ),
      child: Column(
        children: points
            .map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.title,
                            style: TextStyle(
                              fontSize: AppFontSizes.body,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryTo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            point.evidence,
                            style: TextStyle(
                              fontSize: AppFontSizes.body,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEvidenceCard(InterviewSummary summary) {
    return CardContent(
      header: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Evidence',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEvidenceItem('Experience', summary.evidence.experience),
          const SizedBox(height: 12),
          _buildEvidenceItem('Communication', summary.evidence.communication),
          const SizedBox(height: 12),
          _buildEvidenceItem('Technical', summary.evidence.technical),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryTo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRedFlagCard(InterviewSummary summary) {
    return CardContent(
      header: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: AppColors.dangerousColor),
          const SizedBox(width: 8),
          Text(
            'Red Flags',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: AppColors.dangerousColor,
            ),
          ),
        ],
      ),
      child: summary.redFlags.isEmpty
          ? Text(
              'ไม่มีประเด็นเสี่ยงสำคัญ',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: summary.redFlags
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 18,
                            color: AppColors.dangerousColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: AppFontSizes.body,
                                color: AppColors.textPrimaryTo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildTextCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return CardContent(
      header: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: color,
            ),
          ),
        ],
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: AppFontSizes.body,
          color: AppColors.textPrimaryTo,
        ),
      ),
    );
  }

  String _mapRecommendation(String value) {
    switch (value) {
      case 'hire':
        return 'Hire';
      case 'no_hire':
        return 'No Hire';
      default:
        return 'Hold';
    }
  }
}
