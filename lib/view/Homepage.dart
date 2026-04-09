import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SongUlStateless.dart';
import 'PlaylistUl.dart';
import 'Settings.dart';
import '../model/Song.dart';
import '../model/DrawerItem.dart';
import '../controller/Utils.dart';
import '../Database.dart';
import '../model/Constants.dart';
import '../controller/AppLocalizations.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  String _username = Constants.defaultUsername;
  List<Song>? songs;

  final EdgeInsets _cardMargin =
      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0);
  final EdgeInsets _listPadding =
      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
  static const double _tileHeight = 100.0;
  static const double _cardElevation = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadSongs();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(Constants.sharedUsername) ?? '';
    if (mounted) {
      setState(() => _username = name.isNotEmpty ? name : Constants.defaultUsername);
    }
  }

  Future<void> _loadSongs() async {
    final list = await DBProvider.db.getAllSongs();
    if (mounted) setState(() => songs = list);
  }

  Future<void> _routeSongs(BuildContext context) async {
    final list = songs ?? await DBProvider.db.getAllSongs();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SongUlStateless(list, AppLocalizations.of(context).songs_list),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerItems = <dynamic>[
      DrawerItem(AppLocalizations.of(context).settings, Icons.settings,
          (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SettingsStateful(title: AppLocalizations.of(context).settings)),
        ).then((_) => _loadUsername());
      }),
      const Divider(),
      DrawerItem(AppLocalizations.of(context).guide, Icons.help_outline,
          (context) {
        Utils.launchURL(Constants.urlGuide);
      }),
      const Divider(),
      DrawerItem(AppLocalizations.of(context).donate, Icons.card_giftcard,
          (context) {
        Utils.launchURL(Constants.urlDonation);
      }),
    ];

    final drawerOptions = <Widget>[];
    for (final d in drawerItems) {
      if (d is DrawerItem) {
        drawerOptions.add(ListTile(
          leading: Icon(d.icon),
          title: Text(d.title),
          onTap: () => d.action?.call(context),
        ));
      } else if (d is Widget) {
        drawerOptions.add(d);
      }
    }

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_username),
              accountEmail: const Text(''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Text(
                  _username.isNotEmpty ? _username[0].toUpperCase() : 'S',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(child: ListView(children: drawerOptions)),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).title),
      ),
      body: ListView(children: _buildCards(context)),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    return [
      const Padding(padding: EdgeInsets.all(20.0)),
      Card(
        margin: _cardMargin,
        elevation: _cardElevation,
        child: SizedBox(
          height: _tileHeight,
          child: ListTile(
            contentPadding: _listPadding,
            leading: const Icon(Icons.book),
            title: Text(AppLocalizations.of(context).songs_book),
            subtitle: Text(AppLocalizations.of(context).songs_book_desc),
            onTap: () => _routeSongs(context),
          ),
        ),
      ),
      Card(
        margin: _cardMargin,
        elevation: _cardElevation,
        child: SizedBox(
          height: _tileHeight,
          child: ListTile(
            contentPadding: _listPadding,
            leading: const Icon(Icons.album),
            title: Text(AppLocalizations.of(context).playlist),
            subtitle: Text(AppLocalizations.of(context).playlist_desc),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistUlStateful(
                    title: AppLocalizations.of(context).playlist,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }
}
