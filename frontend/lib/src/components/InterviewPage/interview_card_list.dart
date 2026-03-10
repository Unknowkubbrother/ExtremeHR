import 'package:client/src/components/InterviewPage/interview_card.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/interview_model.dart';
import 'package:client/src/services/interview_service.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:flutter/material.dart';

class InterviewCardList extends StatefulWidget {
  const InterviewCardList({super.key});

  @override
  State<InterviewCardList> createState() => _InterviewCardListState();
}

class _InterviewCardListState extends State<InterviewCardList> {
  final InterviewService _interviewService = InterviewService();
  final AuthStorage _authStorage = AuthStorage();

  List<InverViewCardModel> interviewCardList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInterviews();
  }

  Future<void> _fetchInterviews() async {
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        final interviews = await _interviewService.getInterviews(token);
        if (mounted) {
          setState(() {
            interviewCardList = interviews;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'No auth token found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load interviews';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Expanded(child: Center(child: Text(errorMessage!)));
    }

    if (interviewCardList.isEmpty) {
      return const Expanded(child: Center(child: Text("No interviews found")));
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _fetchInterviews,
        child: ListView.separated(
          itemCount: interviewCardList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InterviewCard(
                id: interviewCardList[index].id,
                icon: Icons.work_outline,
                action: () {
                  debugPrint("Interview Card Clicked");
                },
                state: interviewCardList[index].state,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interviewCardList[index].title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppFontSizes.body,
                      ),
                    ),
                    Text(
                      interviewCardList[index].company,
                      style: TextStyle(fontSize: AppFontSizes.caption),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
