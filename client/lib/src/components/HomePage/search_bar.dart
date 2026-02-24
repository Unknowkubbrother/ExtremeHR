import 'dart:async';
import 'package:flutter/material.dart';

class SearchJobBar extends StatefulWidget {
  const SearchJobBar({super.key, required this.onSearch});
  final void Function(String q) onSearch;

  @override
  State<SearchJobBar> createState() => _SearchJobBarState();
}

class _SearchJobBarState extends State<SearchJobBar> {
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) {
        _t?.cancel();
        _t = Timer(const Duration(milliseconds: 500), () {
          print("search: $v");
          widget.onSearch(v.trim());
        });
      },
      decoration: InputDecoration(
        hintText: "Search",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
