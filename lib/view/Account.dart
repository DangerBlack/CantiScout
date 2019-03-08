import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/Song.dart';
import '../model/User.dart';
import '../model/Constants.dart';
import '../controller/Utils.dart';
import '../view/SongULStateless.dart';
import '../Database.dart';

class AccountStateful extends StatefulWidget {
  final User user;

  AccountStateful({Key key, this.title, this.user}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  Account createState() => Account(user);
//_MyHomePageState createState() => _MyHomePageState();
}

class Account extends State {
  User user;
  final myController = TextEditingController();
  final passwordController1 = TextEditingController();
  final passwordController2 = TextEditingController();
  final passwordController3 = TextEditingController();
  bool _validate = false;

  Account(this.user) : super();

  routePlaylistSong(BuildContext context, String title, int id) async {
    //TODO: Aprire playlist appena creata!
    List<Song> songs = await DBProvider.db.getAllPlaylistSongs(id);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SongUlStateless(songs, title, user)),
      //MaterialPageRoute(builder: (context) => SongUlStateful(title: 'Flutter Demo Home Page')),
    );
  }

  createPlaylist(BuildContext context) async {
    var text = myController.text;
    if (text.isNotEmpty) {
      print(text);
      int t = await DBProvider.db.newPlaylist(text);
      routePlaylistSong(context, text, t);
      _validate = false;
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  _deleteAccount(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(Constants.sharedMail, Constants.defaultMail);
    prefs.setString(Constants.sharedName, Constants.defaultName);
    prefs.setString(Constants.sharedToken, "");
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //updateList();
    return Scaffold(
      body: Center(
        child: ListView(children: [
          new Container(
            height: 200,
            child: CircleAvatar(
              //radius: 50,
              //radius: 48.0,
              radius: 18.0,
              child: ClipOval(
                child: Image.network(
                    Constants.gravatarUrl + Utils.generateMd5(user.mail)),
              ),
              //NetworkImage(Constants.gravatarUrl + Utils.generateMd5(user.mail)),
              //Image.asset('assets/flutter-icon.png'),
              backgroundColor: Colors.transparent,
            ),
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "MANAGE USER PASSWORD",
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: TextField(
              textAlign: TextAlign.center,
              controller: passwordController1,
              decoration: InputDecoration(
                labelText: 'Old password',
                errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: TextField(
              textAlign: TextAlign.center,
              controller: passwordController2,
              decoration: InputDecoration(
                labelText: 'New password',
                errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: TextField(
              textAlign: TextAlign.center,
              controller: passwordController3,
              decoration: InputDecoration(
                labelText: 'New password (confirm)',
                errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),
            ),
          ),
          Row(children: [
            Expanded(
              child: FlatButton(
                child: Text(
                  "ANNULLA",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: FlatButton(
                child: Text(
                  "CAMBIA",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: () {
                  createPlaylist(context);
                },
              ),
            ),
          ]),
          Padding(
              padding: EdgeInsets.only(
                  left: 40.0, right: 40.0, top: 100.0, bottom: 10),
              child: Text(
                "LOGOUT",
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: SizedBox(
              height: 40.0,
              child: RaisedButton(
                elevation: 5.0,
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0)),
                color: Theme.of(context).primaryColor,
                child: Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                onPressed: () {
                  _deleteAccount(context);
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
