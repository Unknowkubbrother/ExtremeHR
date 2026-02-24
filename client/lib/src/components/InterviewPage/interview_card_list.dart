import 'package:client/src/components/InterviewPage/interview_card.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/interview_model.dart';
import 'package:flutter/material.dart';

class InterviewCardList extends StatefulWidget {
  const InterviewCardList({super.key});

  @override
  State<InterviewCardList> createState() => _InterviewCardListState();
}

class _InterviewCardListState extends State<InterviewCardList> {
  List<InverViewCardModel> interviewCardList = [
    InverViewCardModel(
      id: "1",
      state: 0,
      title: "UX Designer",
      company: "Google",
    ),
    InverViewCardModel(
      id: "2",
      state: 1,
      title: "Software Engineer",
      company: "Microsoft",
    ),
    InverViewCardModel(
      id: "3",
      state: 2,
      title: "Data Scientist",
      company: "Meta",
    ),
    InverViewCardModel(
      id: "4",
      state: 3,
      title: "Product Manager",
      company: "Apple",
    ),
    InverViewCardModel(
      id: "5",
      state: 3,
      title: "Project Manager",
      company: "Amazon",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}
