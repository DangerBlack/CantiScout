import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:connectivity/connectivity.dart';
import '../model/Song.dart';
import '../model/Tag.dart';
import '../Database.dart';
import '../controller/Updater.dart';
import '../controller/AppLocalizations.dart';

class EditSongText extends StatefulWidget {
  final Song song;
  final List<bool> opt;
  EditSongText({Key key, this.song, this.opt}) : super(key: key);

  @override
  EditSongTextState createState() => EditSongTextState(this.song, this.opt);
}

class EditSongTextState extends State {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final myController = TextEditingController();

  /*final RegExp expChord = new RegExp(r"\[([^\]]*)\]");
  final RegExp expSharp = new RegExp(r"#.*");
  final RegExp expComment = new RegExp(r".*\{(.*)\}.*");
  final RegExp expCommentL = new RegExp(r".*\{(.*):(.*)\}.*");
  final RegExp expInlineChorus =
      new RegExp(r".*\{(soc|start_of_chorus)\}(.*)\{(eoc|end_of_chorus)\}.*");

  final RegExp expTComment = new RegExp(r"c|comment");
  final RegExp expTitleComment = new RegExp(r"t|title");
  final RegExp expAuthorComment = new RegExp(r"a|author");
  final RegExp expChorusStart = new RegExp(r"soc|start_of_chorus");
  final RegExp expChorusEnd = new RegExp(r"eoc|end_of_chorus");
  */
  Song song;
  List<bool> opt;

  //double fSize = 18.0;
  //FontWeight fWeight = FontWeight.normal;
  //FontStyle fStyle = FontStyle.normal;

  //int numberOfDays = 31;
  //double previousfSize;

  //List<Widget> w = new List<Widget>();

  bool _offline = true;

  loadTagList() async {
    print("vuoto!");
    List<Tag> tags = await DBProvider.db.getTagsBySongId(this.song.id);
    tags.forEach((t) {
      print("#" + t.tag);
    });
    setState(() {
      this.song.tags = tags;
      build(context);
    });
  }

  checkNetwork() async {
    var result = await (Connectivity().checkConnectivity());
    print(result);
    if ((result == ConnectivityResult.wifi) ||
        (result == ConnectivityResult.mobile)) {
      setState(() {
        _offline = false;
      });
    }
    if (result == ConnectivityResult.none) {
      setState(() {
        _offline = true;
      });
    }
  }

  @override
  initState() {
    myController.text = song.body ?? "";
    checkNetwork();

    super.initState();
  }

  EditSongTextState(Song song, List<bool> opt) {
    print("rebuild");
    this.song = song;
    this.opt = opt;
    //loadTagList();
  }

  _uploadSong(BuildContext context) async {
    String text = myController.text;
    song.body = text;
    int res = await Updater.updateSong(song,opt);
    if (res < 0) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: new Text(AppLocalizations.of(context).unable_to_update_song),
        duration: new Duration(seconds: 10),
      ));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(this.song.title),
      ),
      body: _buildSong(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _offline ? null : () => _uploadSong(context),
        tooltip: _offline ? AppLocalizations.of(context).unable_to_save: AppLocalizations.of(context).save,
        child: Icon(Icons.save),
        backgroundColor:
            _offline ? Colors.grey : Theme.of(context).primaryColor,
      ),
    );
  }

  printD(String s) {
    //print(s);
  }

  Widget _buildSong(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: EdgeInsets.all(10.0),
        child: TextField(
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context).edit_song + song.title),
          maxLines: 500,
          controller: myController,
        ),
      )
    ]);
  }

// Be sure to cancel subscription after you are done
  dispose() {
    myController.dispose();
    super.dispose();
  }
}
