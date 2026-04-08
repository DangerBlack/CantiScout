import 'package:flutter/material.dart';
import '../view/SongUlSearch.dart';

class CustomSearchDelegate extends SearchDelegate {
  SongUlSearch? songsState;

  CustomSearchDelegate() : super() {
    songsState = SongUlSearch(query);
  }

  String needle = '';

  CustomSearchDelegate.builder(String text) : super() {
    query = text;
    needle = text;
    songsState = SongUlSearch(query);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          needle = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    if (needle.isNotEmpty) {
      query = needle;
      needle = '';
    }
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    songsState = SongUlSearch(query);
    return SongUlSearchStateful(
        title: 'titolo', search: query, state: songsState!);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final state = songsState;
    if (state == null || !state.mounted) {
      songsState = SongUlSearch(query);
    } else {
      state.search = query;
    }
    return SongUlSearchStateful(
        title: 'titolo', search: query, state: songsState!);
  }
}
