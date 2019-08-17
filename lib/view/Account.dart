import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/Song.dart';
import '../model/User.dart';
import '../model/Constants.dart';
import '../controller/Utils.dart';
import '../controller/Updater.dart';
import '../view/SongUlStateless.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';


class AccountStateful extends StatefulWidget {
  final User user;
  final VoidCallback onLogoutCallback;

  AccountStateful({Key key, this.title, this.user, this.onLogoutCallback})
      : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  Account createState() => Account(user, onLogoutCallback);
//_MyHomePageState createState() => _MyHomePageState();
}

class Account extends State {
  User user;
  final myController = TextEditingController();
  final passwordController1 = TextEditingController();
  final passwordController2 = TextEditingController();
  final passwordController3 = TextEditingController();
  bool _validate = false;
  final VoidCallback onLogoutCallback;

  Account(this.user, this.onLogoutCallback) : super();

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

  changePassword(BuildContext context) async {
    var oldPswd = passwordController1.text;
    var newPswd = passwordController2.text;
    var newPswd2 = passwordController3.text;
    if (oldPswd.isNotEmpty && newPswd.isNotEmpty && newPswd2.isNotEmpty) {
      if (newPswd == newPswd2 && oldPswd!=newPswd) {
        int s = await Updater.updatePswd(oldPswd, newPswd);
        if(s>0){
          passwordController1.text = "";
          passwordController2.text = "";
          passwordController3.text = "";
          _showSuccessDialog();
        }
        setState(() {
          _validate = false;
        });
      } else {
        setState(() {
          _validate = false;
        });
      }
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(AppLocalizations.of(context).password_changed),
          content: new Text(AppLocalizations.of(context).password_changed_success),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _deleteAccount(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int s = await Updater.expireToken();
    if (s > 0) {
      print("ok");
    } else {
      print("fail");
    }
    prefs.setString(Constants.sharedMail, Constants.defaultMail);
    prefs.setString(Constants.sharedName, Constants.defaultName);
    prefs.setString(Constants.sharedToken, "");
    onLogoutCallback();
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
                child: FlatButton(
                onPressed: () => Utils.launchURL(Constants.gravatarBaseUrl),
                child:
                ClipOval(
                  child: Image.network(
                      Constants.gravatarUrl + Utils.generateMd5(user.mail)),
                ),
                //NetworkImage(Constants.gravatarUrl + Utils.generateMd5(user.mail)),
                //Image.asset('assets/flutter-icon.png'),
                ),
                backgroundColor: Colors.transparent,
              ),
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                AppLocalizations.of(context).manage_user_password,
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: TextField(
              textAlign: TextAlign.center,
              controller: passwordController1,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).old_password,
                errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: TextField(
              textAlign: TextAlign.center,
              controller: passwordController2,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).new_password,
                errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
            child: TextField(
              textAlign: TextAlign.center,
              controller: passwordController3,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).new_password+" "+AppLocalizations.of(context).confirmed,
                errorText: _validate ? 'Value Can\'t Be Empty' : null,
              ),
            ),
          ),
          Row(children: [
            Expanded(
              child: FlatButton(
                child: Text(
                  AppLocalizations.of(context).undo,
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
                  AppLocalizations.of(context).change,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: () {
                  changePassword(context);
                },
              ),
            ),
          ]),
          Padding(
              padding: EdgeInsets.only(
                  left: 40.0, right: 40.0, top: 100.0, bottom: 10),
              child: Text(
                AppLocalizations.of(context).logout.toUpperCase(),
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
                  AppLocalizations.of(context).logout,
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
