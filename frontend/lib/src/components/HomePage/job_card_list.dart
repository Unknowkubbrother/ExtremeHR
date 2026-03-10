import 'package:client/src/components/HomePage/card_list.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:client/src/components/JobDetailPage/job_detail_page.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:client/src/models/jobList_model.dart';

class JobCardList extends StatefulWidget {
  final List<int>? filterJobIds;
  final String? filter;
  const JobCardList({super.key, this.filterJobIds, this.filter});

  @override
  State<JobCardList> createState() => _JobCardListState();
}

class _JobCardListState extends State<JobCardList> {
  final storage = AuthStorage();
  final jobServices = JobServices();
  List<JobListItem> jobs = [];

  Future<void> getJobs() async {
    try {
      final token = await storage.getToken();

      final response = await jobServices.getJobs(token!, filter: widget.filter);

      if (!mounted) return;
      setState(() {
        jobs = response;
      });

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load jobs')));
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getJobs();
  }

  @override
  void didUpdateWidget(JobCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.filterJobIds != widget.filterJobIds) {
      if (oldWidget.filter != widget.filter && widget.filterJobIds == null) {
        getJobs();
      }
    }
  }

  List<JobListItem> get _displayedJobs {
    if (widget.filterJobIds == null) return jobs;
    final idOrder = widget.filterJobIds!;
    final filtered = jobs.where((j) => idOrder.contains(j.jobId)).toList();
    filtered.sort(
      (a, b) => idOrder.indexOf(a.jobId).compareTo(idOrder.indexOf(b.jobId)),
    );
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final displayJobs = _displayedJobs;
    return Expanded(
      child: ListView.separated(
        itemCount: displayJobs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = displayJobs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CardList(
              icon: Icons.work_outline,
              action: () {
                debugPrint("Job Card Clicked");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        JobDetailPage(jobId: job.jobId.toString()),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSizes.body,
                    ),
                  ),
                  Text(
                    job.company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppFontSizes.caption),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16),
                      Expanded(
                        child: Text(
                          job.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: AppFontSizes.caption),
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.monetization_on_outlined, size: 16),
                      Text(
                        job.salary.toString(),
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
