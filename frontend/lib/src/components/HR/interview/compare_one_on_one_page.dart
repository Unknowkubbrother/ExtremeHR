import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/models/candidate_compare_model.dart';
import 'package:flutter/material.dart';

class CompareOneOnOneMockPage extends StatefulWidget {
  final List<CandidateCompareModel> candidates;

  const CompareOneOnOneMockPage({super.key, required this.candidates});

  @override
  State<CompareOneOnOneMockPage> createState() =>
      _CompareOneOnOneMockPageState();
}

class _CompareOneOnOneMockPageState extends State<CompareOneOnOneMockPage> {
  CandidateCompareModel? _cand1;
  CandidateCompareModel? _cand2;

  @override
  void initState() {
    super.initState();
    if (widget.candidates.isNotEmpty) {
      _cand1 = widget.candidates[0];
      if (widget.candidates.length > 1) {
        _cand2 = widget.candidates[1];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        title: const Text(
          "1-on-1 Compare",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: widget.candidates.length < 2
          ? const Center(child: Text("Not enough candidates to compare."))
          : Column(
              children: [
                // Dropdowns for selecting candidates
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(child: _buildDropdown(1)),
                      const SizedBox(width: 12),
                      const Text(
                        "VS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown(2)),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_cand1 != null)
                            Expanded(child: _buildCompareColumn(_cand1!)),
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 400,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 16),
                          if (_cand2 != null)
                            Expanded(child: _buildCompareColumn(_cand2!)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDropdown(int index) {
    final selectedValue = index == 1 ? _cand1 : _cand2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CandidateCompareModel>(
          isExpanded: true,
          value: selectedValue,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: widget.candidates.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                c.candidateName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (index == 1) {
                  _cand1 = val;
                } else {
                  _cand2 = val;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompareColumn(CandidateCompareModel cand) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    (cand.summary.totalScore * 10).toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Total Score",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressBar("Experience", cand.summary.experienceScore),
          const SizedBox(height: 16),
          _buildProgressBar("Communication", cand.summary.communicationScore),
          const SizedBox(height: 16),
          _buildProgressBar("Technical", cand.summary.technicalScore),
          const SizedBox(height: 24),
          if (cand.summary.strengths.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  "Strengths",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...cand.summary.strengths.map(
              (s) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(color: Colors.green)),
                  Expanded(
                    child: Text(s.title, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (cand.summary.weaknesses.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange[800]),
                const SizedBox(width: 6),
                Text(
                  "Weaknesses",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...cand.summary.weaknesses.map(
              (w) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(color: Colors.orange)),
                  Expanded(
                    child: Text(w.title, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              (score * 10).toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.grey[200],
            color: AppColors.primary,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
