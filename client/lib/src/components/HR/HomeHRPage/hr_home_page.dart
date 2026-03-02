import 'package:client/src/components/HR/HomeHRPage/dashboard_page.dart';
import 'package:client/src/components/HR/HomeHRPage/job_list_hr.dart';
import 'package:client/src/components/HomePage/search_bar.dart';
import 'package:flutter/material.dart';

class HRHomePage extends StatefulWidget {
  const HRHomePage({super.key});

  @override
  State<HRHomePage> createState() => _HRHomePageState();
}

void _search(String q) {
  debugPrint("search: $q");
}

class _HRHomePageState extends State<HRHomePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          DashBoard(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SearchJobBar(onSearch: _search),
          ),
          const SizedBox(height: 16),
          JobListHR(),
        ],
      ),
    );
  }
}
