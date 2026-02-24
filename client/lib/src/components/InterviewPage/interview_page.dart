import 'package:flutter/material.dart';
import 'package:client/src/components/InterviewPage/interview_card_list.dart';

class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [InterviewCardList()]);
  }
}
