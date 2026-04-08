import 'package:flutter/material.dart';
import 'SongUl.dart';
import '../Database.dart';
import '../model/Song.dart';

class SongUlSearchStateful extends StatefulWidget {
  const SongUlSearchStateful(
      {Key? key, this.title, this.search, required this.state})
      : super(key: key);

  final String? title;
  final String? search;
  final SongUlSearch state;

  @override
  SongUlSearch createState() => state;
}

class SongUlSearch extends SongUl {
  String _search;

  SongUlSearch(this._search) : super() {
    leadingIcon = Icons.music_note;
  }

  @override
  void initState() {
    super.initState();
    updateList();
  }

  Future<void> updateListS(String search) async {
    final List<Song> lg = await DBProvider.db.getSongs(search);
    if (mounted) {
      setState(() => l.list = lg);
    }
  }

  @override
  Future<void> updateList() async {
    if (l.list.isEmpty) {
      final List<Song> lg = await DBProvider.db.getSongs(_search);
      if (mounted) setState(() => l.list = lg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildList();
  }

  String get search => _search;
  set search(String v) {
    _search = v;
    updateListS(_search);
  }

  @override
  void dispose() {
    l.list = [];
    super.dispose();
  }
}
