import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/components/shared/confirm.dart';
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
  final ConfirmDialog _acceptDialog = const ConfirmDialog(
    title: 'Accept this candidate?',
    content: 'This candidate will move to the accepted stage.',
    confirmText: 'Accept',
    cancelText: 'Cancel',
    confirmColor: Colors.green,
    cancelColor: AppColors.textPrimaryTo,
  );
  final ConfirmDialog _rejectDialog = const ConfirmDialog(
    title: 'Reject this candidate?',
    content: 'This action cannot be undone.',
    confirmText: 'Reject',
    cancelText: 'Cancel',
    confirmColor: Colors.red,
    cancelColor: AppColors.textPrimaryTo,
  );

  InterviewSummary? _summary;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isDecisionUpdating = false;
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
        const SnackBar(content: Text('Summary generated successfully')),
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

  Future<void> _acceptCandidate() async {
    final confirmed = await _acceptDialog.show(context);
    if (confirmed != true) {
      return;
    }

    await _runDecisionAction(
      (token) => _interviewService.acceptInterview(token, widget.interviewId),
    );
  }

  Future<void> _rejectCandidate() async {
    final confirmed = await _rejectDialog.show(context);
    if (confirmed != true) {
      return;
    }

    await _runDecisionAction(
      (token) => _interviewService.rejectInterview(token, widget.interviewId),
    );
  }

  Future<void> _runDecisionAction(
    Future<dynamic> Function(String token) action,
  ) async {
    setState(() => _isDecisionUpdating = true);

    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      await action(token);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isDecisionUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
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
        const SizedBox(height: 20),
        _buildMetaCard(_summary!),
        const SizedBox(height: 16),
        _buildTextCard(
          title: 'Executive Summary',
          icon: Icons.summarize_outlined,
          color: AppColors.primary,
          content: _summary!.suggestionSummary,
        ),
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
          title: 'Next Step',
          icon: Icons.arrow_forward_outlined,
          color: AppColors.primary,
          content: _summary!.nextStep,
        ),
        if (widget.canGenerate) ...[
          const SizedBox(height: 16),
          _buildDecisionCard(),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 460,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage ?? 'No summary available for this interview yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.canGenerate) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateSummary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
                  _isGenerating ? 'Generating summary...' : 'Generate Summary',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationPill(InterviewSummary summary) {
    final recommendation = summary.recommendation;
    Color backgroundColor = AppColors.primary.withValues(alpha: 0.18);

    if (recommendation == 'hire') {
      backgroundColor = AppColors.positiveColor.withValues(alpha: 0.18);
    } else if (recommendation == 'no_hire') {
      backgroundColor = AppColors.dangerousColor.withValues(alpha: 0.18);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _mapRecommendation(summary.recommendation),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildScoreCard(InterviewSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color(0xFF233876),
            Color(0xFF324AA8),
            Color(0xFF465FCA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Assessment',
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.82),
                        fontSize: AppFontSizes.body,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.totalScore.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Average score from experience, communication, and technical',
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.82),
                        fontSize: AppFontSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRecommendationPill(summary),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 340,
            child: _buildScoreChip(
              'Confidence',
              summary.confidence,
              subtitle: 'confidence',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, double value, {String? subtitle}) {
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
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
          Text(
            'Score Breakdown',
            style: TextStyle(
              fontSize: AppFontSizes.subtitle,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryTo,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Experience', summary.experienceScore),
          const SizedBox(height: 14),
          _buildMetricRow('Communication', summary.communicationScore),
          const SizedBox(height: 14),
          _buildMetricRow('Technical', summary.technicalScore),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: AppColors.textPrimaryTo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
          _buildEvidenceItem(
            'Experience',
            summary.evidence.experience,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildEvidenceItem(
            'Communication',
            summary.evidence.communication,
            AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildEvidenceItem(
            'Technical',
            summary.evidence.technical,
            AppColors.positiveColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(String title, String value, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
              'No major red flags',
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

  Widget _buildDecisionCard() {
    return CardContent(
      header: Row(
        children: [
          Icon(Icons.gavel_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Decision',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.subtitle,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isDecisionUpdating ? null : _acceptCandidate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isDecisionUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isDecisionUpdating ? null : _rejectCandidate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerousColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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
