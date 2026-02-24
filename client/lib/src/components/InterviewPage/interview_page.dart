import 'package:flutter/material.dart';

class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text("Interview $index"),
          subtitle: Text("Interview $index"),
          trailing: Icon(Icons.arrow_forward_ios),
        );
      },
    );
  }
}
