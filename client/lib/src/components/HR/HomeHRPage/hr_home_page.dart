import 'package:client/src/components/HR/HomeHRPage/dashboard_page.dart';
import 'package:flutter/material.dart';

class HRHomePage extends StatefulWidget {
  const HRHomePage({super.key});

  @override
  State<HRHomePage> createState() => _HRHomePageState();
}

class _HRHomePageState extends State<HRHomePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const DashBoard(),
          const SizedBox(height: 16),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recent activity",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                _ActivityRow("New applicant: John • Frontend Dev", "2m ago"),
                SizedBox(height: 8),
                _ActivityRow("New applicant: John • Frontend Dev", "2m ago"),
                SizedBox(height: 8),
                _ActivityRow("New applicant: John • Frontend Dev", "2m ago"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String time;
  const _ActivityRow(this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Text(time, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
