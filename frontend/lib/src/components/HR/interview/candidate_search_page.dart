import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/candidate_search_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:flutter/material.dart';
import 'package:client/src/components/HR/interview/candidate_resume_page.dart';
import 'package:client/src/models/status_enum.dart';

class CandidateSearchPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const CandidateSearchPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<CandidateSearchPage> createState() => _CandidateSearchPageState();
}

class _CandidateSearchPageState extends State<CandidateSearchPage> {
  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authStorage = AuthStorage();
  final TextEditingController _searchController = TextEditingController();

  bool _isInitializing = true;
  bool _isSearching = false;
  List<CandidateSearchResultModel> _results = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initEmbeddings();
  }

  Future<void> _initEmbeddings() async {
    setState(() {
      _isInitializing = true;
      _error = '';
    });
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        await _interviewService.initCandidateEmbeddings(token, widget.jobId);
      }
    } catch (e) {
      debugPrint('Init Error: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _handleSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isSearching = true;
        _error = '';
        _results = [];
      });
    }

    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        // REAL API CALL
        final data = await _interviewService.searchCandidates(
          token,
          widget.jobId,
          _searchController.text,
        );

        if (mounted) {
          setState(() {
            _results = data;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSearching = false);
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
          "AI Candidate Search",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          if (_isInitializing)
            _buildInitializingState()
          else
            Expanded(
              child: _error.isNotEmpty
                  ? _buildErrorState()
                  : _isSearching
                  ? _buildSearchingState()
                  : _results.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What kind of candidate are you looking for?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.body,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _handleSearch(),
            decoration: InputDecoration(
              hintText: "e.g. 'หาคนแก้ปัญหาเก่งๆ ประสบการณ์ 3 ปี'",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(
                Icons.psychology,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: _handleSearch,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              "Preparing candidates data...",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "AI is learning about your applicants",
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Searching & Ranking...",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Finding your best match",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "Search for your ideal candidate",
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "Error: $_error",
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildCandidateResultCard(result, index + 1);
      },
    );
  }

  Widget _buildCandidateResultCard(
    CandidateSearchResultModel result,
    int rank,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank == 1 ? AppColors.primary : Colors.grey[200]!,
          width: rank == 1 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rank == 1 ? AppColors.primary : Colors.grey[900],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "#$rank",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.candidateName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        result.score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.reason,
                        style: const TextStyle(
                          height: 1.6,
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // EVIDENCE SECTION
                if (result.evidence.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "EVIDENCE FROM DOCUMENTS",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...result.evidence.map(
                    (snippet) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        "\"${snippet.trim()}\"",
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CandidateResumePage(
                            candidateId: result.candidateId.toString(),
                            interviewId: result.interviewId.toString(),
                            candidateName: result.candidateName,
                            initialStatus: Status.view,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "View Profile",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
