import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SongUlStateless.dart';
import 'PlaylistUl.dart';
import 'Settings.dart';
import 'LoginSignUpPage.dart';
import 'Account.dart';
import '../model/Song.dart';
import '../model/DrawerItem.dart';
import '../controller/Updater.dart';
import '../controller/Utils.dart';
import '../Database.dart';

import '../model/SongList.dart';
import '../model/Constants.dart';
import '../model/User.dart';

import '../controller/Authentication.dart';
import '../controller/Routing.dart';

import '../controller/AppLocalizations.dart';

class Homepage extends StatefulWidget {
  Homepage({Key key}) : super(key: key);

  @override
  HomepageState createState() => HomepageState();
//_MyHomePageState createState() => _MyHomePageState();
}

class HomepageState extends State {
  User user = new User("Unknown", "Unknown");

  EdgeInsets _cardMargin =
      new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0);
  EdgeInsets _listPadding =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
  double _tileHeight = 100.0;
  double _cardElevation = 1.0;
  List<Song> songs;

  bool syncing = false;

  var drawerItems = [];

  _buildDrawList() {
    drawerItems = [
      new DrawerItem(AppLocalizations.of(context).sync, Icons.sync, (context) async {
        updateListRemote();
      }),
      user.logged ? new DrawerItem(AppLocalizations.of(context).account, Icons.account_circle, (context) async {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AccountStateful(
                    title: AppLocalizations.of(context).account,
                    user: user,
                    onLogoutCallback: () =>
                    {
                    Navigator.pop(context),
                    _loadUser()
                    },
                  )),
        );
      }):new Padding(padding: EdgeInsets.all(0),),
      new Divider(),
      new DrawerItem(AppLocalizations.of(context).settings, Icons.settings, (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SettingsStateful(title: "Settings")),
        );
      }),
      new DrawerItem(AppLocalizations.of(context).guide, Icons.help_outline, (context) {
        Utils.launchURL(Constants.urlGuide);
      }),
      new Divider(),
      new DrawerItem(AppLocalizations.of(context).donate, Icons.card_giftcard, (context) {
        Utils.launchURL(Constants.urlDonation);
      }),
    ];
  }

  updateListRemote() async {
    songs = await DBProvider.db.getAllSongs();
    setState(() {
      this.syncing = true;
    });
    SongList lg = await Updater.updateSongs(true);
    setState(() {
      this.syncing = false;
    });
    if (lg.list.isNotEmpty) {
      print("Aggiornata!");
      songs = await DBProvider.db.getAllSongs();
    } else {
      print("Up to date");
    }
  }
  updateList() async {
    songs = await DBProvider.db.getAllSongs();
  }

  routeSongs(BuildContext context) async {
    if (songs == null) {
      songs = await DBProvider.db.getAllSongs();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SongUlStateless(songs, AppLocalizations.of(context).songs_list, user = user)),
      //MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
    );
  }

  _onSelectItem(BuildContext context, int index) {
    DrawerItem d = drawerItems[index];
    if (d.action != null) {
      d.action(context);
    }
  }

  _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String mail =
        (prefs.getString(Constants.sharedMail) ?? Constants.defaultMail);
    String name =
        (prefs.getString(Constants.sharedName) ?? Constants.defaultName);
    User userT = User.noPassword(name, mail);
    if (mail != Constants.defaultMail) {
      userT.logged = true;
    }
    setState(() {
      user = userT;
      build(context);
    });
    Routing.checkRoutingLinks(context, user);
    _buildDrawList();
    return user;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    updateListRemote();
  }

  List<Widget> _buildCards(BuildContext context) {
    List<Widget> l = new List<Widget>();

    l.add(Padding(
      padding: EdgeInsets.all(20.0),
    ));
    l.add(Card(
      margin: _cardMargin,
      elevation: _cardElevation,
      child: Container(
        height: _tileHeight,
        child: ListTile(
            contentPadding: _listPadding,
            leading: Icon(syncing?Icons.update:Icons.book),
            title: Text(AppLocalizations.of(context).songs_book),
            subtitle: Text(AppLocalizations.of(context).songs_book_desc),
            onTap: () {
              routeSongs(context);
              /*Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
                          );*/
            }),
      ),
    ));
    l.add(Card(
      margin: _cardMargin,
      elevation: _cardElevation,
      child: Container(
        height: _tileHeight,
        child: ListTile(
            contentPadding: _listPadding,
            leading: Icon(Icons.album),
            title: Text(AppLocalizations.of(context).playlist),
            subtitle: Text(AppLocalizations.of(context).playlist_desc),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PlaylistUlStateful(
                          title: 'Flutter Demo Home Page',
                          user: user,
                        )),
              );
            }),
      ),
    ));

    /*l.add(Card(
      margin: _cardMargin,
      elevation: _cardElevation,
      child: Container(
        height: _tileHeight,
        child: ListTile(
          contentPadding: _listPadding,
          leading: Icon(Icons.lock),
          title: Text('Altro'),
          subtitle: Text('Altro...'),
        ),
      ),
    ));*/

    if (!user.logged) {
      l.add(Card(
        margin: _cardMargin,
        elevation: _cardElevation,
        child: Container(
          height: _tileHeight,
          child: ListTile(
            contentPadding: _listPadding,
            leading: Icon(Icons.account_circle),
            title: Text(AppLocalizations.of(context).login),
            subtitle:
                Text(AppLocalizations.of(context).login_desc),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LoginSignUpPage(
                        auth: new Auth(),
                        onSignedIn: () =>
                            {Navigator.pop(context), _loadUser()})),
              );
            },
          ),
        ),
      ));
    }

    return l;
  }

  @override
  Widget build(BuildContext context) {
    updateList();
    _buildDrawList();

    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      if (d is DrawerItem) {
        drawerOptions.add(new ListTile(
          leading: new Icon(d.icon),
          title: new Text(d.title),
//            selected: i == _selectedDrawerIndex,
          onTap: () => _onSelectItem(context, i),
        ));
      } else {
        drawerOptions.add(d);
      }
    }

    return Scaffold(
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
                accountName: new Text(user.name ?? Constants.defaultName),
                accountEmail: new Text(user.mail ?? Constants.defaultMail),
                currentAccountPicture: new CircleAvatar(
                  backgroundImage: NetworkImage(
                      Constants.gravatarUrl + Utils.generateMd5(user.mail)),
                )),
            new Expanded(
              child: ListView(children: drawerOptions),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).title),
      ),
      body: ListView(
        children: _buildCards(context),
      ),
    );
  }
}
