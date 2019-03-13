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

class Homepage extends StatefulWidget {
  Homepage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

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

  var drawerItems = [];

  _buildDrawList() {
    drawerItems = [
      new DrawerItem("Sincronizza", Icons.sync, null),
      user.logged ? new DrawerItem("Account", Icons.account_circle, (context) async {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AccountStateful(
                    title: "Account",
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
      new DrawerItem("Impostazioni", Icons.settings, (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SettingsStateful(title: "Settings")),
        );
      }),
      new DrawerItem("Guida", Icons.help_outline, null),
      new Divider(),
      new DrawerItem("Dona", Icons.card_giftcard, null),
    ];
  }

  updateList() async {
    songs = await DBProvider.db.getAllSongs();
    SongList lg = await Updater.updateSongs();
    if (lg.list.isNotEmpty) {
      print("Aggiornata!");
      songs = await DBProvider.db.getAllSongs();
    } else {
      print("Up to date");
    }
  }

  routeSongs(BuildContext context) async {
    if (songs == null) {
      songs = await DBProvider.db.getAllSongs();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SongUlStateless(songs, "Elenco canzoni", user = user)),
      //MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
    );
  }

  _onSelectItem(BuildContext context, int index) {
    DrawerItem d = drawerItems[index];
    if (d.action != null) {
      d.action(context);
    }
  }

  void _onLoggedIn(BuildContext context) {
    Navigator.pop(context);
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
            leading: Icon(Icons.book),
            title: Text('Canzoniere'),
            subtitle: Text('Ascolta tutte le canzoni'),
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
            title: Text('Playlist'),
            subtitle: Text('Tutte le playlist'),
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

    l.add(Card(
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
    ));

    if (!user.logged) {
      l.add(Card(
        margin: _cardMargin,
        elevation: _cardElevation,
        child: Container(
          height: _tileHeight,
          child: ListTile(
            contentPadding: _listPadding,
            leading: Icon(Icons.account_circle),
            title: Text('Login'),
            subtitle:
                Text('Effettua il login per accedere a tutte le funzionalità'),
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
        title: Text('Canti Scout'),
      ),
      body: ListView(
        children: _buildCards(context),
      ),
    );
  }
}
