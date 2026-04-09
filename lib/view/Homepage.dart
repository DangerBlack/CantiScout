import 'package:flutter/material.dart';

import '../controller/AppLocalizations.dart';
import 'PlaylistUl.dart';
import 'Settings.dart';
import 'SongUlStateless.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  final _importSignal = ValueNotifier<int>(0);
  final _playlistSignal = ValueNotifier<int>(0);

  @override
  void dispose() {
    _importSignal.dispose();
    _playlistSignal.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    // Refresh playlist list whenever the user switches to that tab.
    if (index == 1) _playlistSignal.value++;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SongUlStateless(
            [],
            AppLocalizations.of(context).songs_list,
            reloadTrigger: _importSignal,
          ),
          PlaylistUlStateful(
            title: AppLocalizations.of(context).playlist,
            reloadTrigger: _playlistSignal,
          ),
          SettingsStateful(
            title: AppLocalizations.of(context).settings,
            onImportComplete: () => _importSignal.value++,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Canti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Playlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}
