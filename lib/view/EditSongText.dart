import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:connectivity/connectivity.dart';
import 'package:share/share.dart';

import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';
import '../model/Chartset.dart';
import '../Database.dart';
import '../controller/CustomSearchDelegate.dart';
import '../view/ChoosePlaylist.dart';

class EditSongText extends StatefulWidget {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  Song song;
  int numberOfDays = 31;
  int previousNumOfDays;

/*  SongText({
    this.song
  });*/

  EditSongText({Key key, this.song}) : super(key: key);

  @override
  EditSongTextState createState() => EditSongTextState(this.song);
}

class EditSongTextState extends State {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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

  checkNetwork() async{
    var result = await (Connectivity().checkConnectivity());
    print(result);
    if( (result == ConnectivityResult.wifi)||(result == ConnectivityResult.mobile) ){
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
    /*subscription = Connectivity().onConnectivityChanged.listen((
        ConnectivityResult result) {
      // Got a new connectivity status!
      print(result);
      if (result == ConnectivityResult.mobile) {
        setState(() {
          _offline = false;
        });
      }
      if (result == ConnectivityResult.none) {
        setState(() {
          _offline = true;
        });
      }
    });*/
    checkNetwork();

    super.initState();
  }

  EditSongTextState(song) {
    print("rebuild");
    this.song = song;
    //loadTagList();
  }

  _uploadSong(){
    _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: new Text('Error: Errorissimo brutto'),
          duration: new Duration(seconds: 10),
        )
    );
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
        onPressed: _offline ? null : () => _uploadSong,
        tooltip: _offline ? "Unable to Save" : "Save",
        child: Icon(Icons.save),
        backgroundColor: _offline ? Colors.grey : Theme.of(context).primaryColor,
      ),
    );
  }

  printD(String s) {
    //print(s);
  }

  Widget _buildSong(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Edit the song: ' + song.title),
        initialValue: song.body ?? "",
        maxLines: 500,
      ),
    );
  }


// Be sure to cancel subscription after you are done
  dispose() {
    super.dispose();
  }
}
