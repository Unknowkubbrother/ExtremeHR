import 'package:client/src/components/HomePage/card_list.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:client/src/components/JobDetailPage/job_detail_page.dart';

class JobCardList extends StatefulWidget {
  const JobCardList({super.key});

  @override
  State<JobCardList> createState() => _JobCardListState();
}

class _JobCardListState extends State<JobCardList> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        itemCount: 10,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CardList(
              icon: Icons.work_outline,
              action: () {
                debugPrint("Job Card Clicked");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JobDetailPage(jobId: "1"),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Job Title",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSizes.body,
                    ),
                  ),
                  Text(
                    "Company Name",
                    style: TextStyle(fontSize: AppFontSizes.caption),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16),
                      Text(
                        "Job Location",
                        style: TextStyle(fontSize: AppFontSizes.caption),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.monetization_on_outlined, size: 16),
                      Text(
                        "18000",
                        style: TextStyle(fontSize: AppFontSizes.caption),
                      ),
                    ],
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
