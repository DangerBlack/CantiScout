import 'package:flutter/material.dart';

import '../view/SongUlSearch.dart';

class CustomSearchDelegate extends SearchDelegate {
  CustomSearchDelegate({String initialQuery = ''}) {
    query = initialQuery;
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) =>
      SongUlSearchStateful(search: query);

  @override
  Widget buildSuggestions(BuildContext context) =>
      SongUlSearchStateful(search: query);
}
