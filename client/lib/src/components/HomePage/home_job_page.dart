import 'package:client/src/components/HomePage/filter.dart';
import 'package:client/src/components/HomePage/job_card_list.dart';
import 'package:client/src/components/HomePage/recommend.dart';
import 'package:client/src/components/HomePage/search_bar.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:flutter/material.dart';

class HomeJobPage extends StatefulWidget {
  const HomeJobPage({super.key});

  @override
  State<HomeJobPage> createState() => _HomeJobPageState();
}

class _HomeJobPageState extends State<HomeJobPage> {
  final _storage = AuthStorage();
  final _jobServices = JobServices();
  List<int>? _searchJobIds;
  bool _isSearching = false;
  String _currentFilter = 'All';
  String _currentQuery = '';

  void _onFilterChanged(String filter) {
    setState(() {
      _currentFilter = filter;
    });
    if (_currentQuery.isNotEmpty) {
      _search(_currentQuery);
    }
  }

  void _search(String q) async {
    _currentQuery = q;

    if (q.isEmpty) {
      setState(() {
        _searchJobIds = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final token = await _storage.getToken();
      if (token == null) return;

      final results = await _jobServices.searchJobs(
        token,
        q,
        filter: _currentFilter,
      );
      if (!mounted) return;

      setState(() {
        _searchJobIds = results
            .map<int>((r) => int.parse(r['id'].toString()))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SearchJobBar(onSearch: _search),
        ),
        const SizedBox(height: 16),
        Filter(onChanged: _onFilterChanged),
        const SizedBox(height: 16),
        if (_searchJobIds == null) ...[Recommend(), const SizedBox(height: 16)],
        if (_isSearching)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          JobCardList(
            key: ValueKey('$_searchJobIds-$_currentFilter'),
            filterJobIds: _searchJobIds,
            filter: _currentFilter,
          ),
      ],
    );
  }
}
