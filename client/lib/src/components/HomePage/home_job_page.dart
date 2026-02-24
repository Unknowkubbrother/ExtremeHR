import 'package:client/src/components/HomePage/filter.dart';
import 'package:client/src/components/HomePage/job_card_list.dart';
import 'package:client/src/components/HomePage/recommend.dart';
import 'package:client/src/components/HomePage/search_bar.dart';
import 'package:flutter/material.dart';

class HomeJobPage extends StatefulWidget {
  const HomeJobPage({super.key});

  @override
  State<HomeJobPage> createState() => _HomeJobPageState();
}

void _search(String q) {
  debugPrint("search: $q");
}

class _HomeJobPageState extends State<HomeJobPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SearchJobBar(onSearch: _search),
        ),
        const SizedBox(height: 16),
        Recommend(),
        const SizedBox(height: 16),
        Filter(),
        const SizedBox(height: 16),
        JobCardList(),
      ],
    );
  }
}
