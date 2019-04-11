import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share/share.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';
import '../model/Chartset.dart';
import '../model/Choice.dart';
import '../Database.dart';
import '../controller/CustomSearchDelegate.dart';
import '../controller/Updater.dart';
import '../view/ChoosePlaylist.dart';
import '../view/EditSongText.dart';
import '../view/Settings.dart';


import '../controller/AppLocalizations.dart';

class SongText extends StatefulWidget {
  final Song song;

  SongText({Key key, this.song}) : super(key: key);

  @override
  SongTextState createState() => SongTextState(this.song);
}

class SongTextState extends State {
  List<Choice> choices;
  final RegExp expChord = new RegExp(r"\[([^\]]*)\]");
  final RegExp expSharp = new RegExp(r"#.*");
  final RegExp expComment = new RegExp(r".*\{(.*)\}.*");
  final RegExp expCommentL = new RegExp(r".*\{([a-zA-Z0-9_ ]*):(.*)\}.*");
  final RegExp expInlineChorus =
      new RegExp(r".*\{(soc|start_of_chorus)\}(.*)\{(eoc|end_of_chorus)\}.*");

  final RegExp expTComment = new RegExp(r"c|comment");
  final RegExp expTitleComment = new RegExp(r"t|title");
  final RegExp expAuthorComment = new RegExp(r"a|author");
  final RegExp expChorusStart = new RegExp(r"soc|start_of_chorus");
  final RegExp expChorusEnd = new RegExp(r"eoc|end_of_chorus");

  Song song;
  double fSize = Constants.initialFontSize;
  FontWeight fWeight = FontWeight.normal;
  FontStyle fStyle = FontStyle.normal;
  bool _autoscroll = Constants.initialAutoscroll;
  Color _noteColor = Color(Constants.initialColor);
  bool _logged = false;
  double _speed = 5.0;

  //String _fontFamily = "Roboto";
  //String _fontFamily = "Inconsolata";
  String _fontFamily = Constants.initialFontStyle;

  //String _fontFamily = "NotCourierSans";
  //Choice _selectedChoice = choices[0];

  int numberOfDays = 31;
  double previousfSize;
  ScrollController _controller;
  int _songLength = 0;

  List<Widget> w = new List<Widget>();

  String reportValue = "copiright";
  TextEditingController _controllerReportDesc;

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

  SongTextState(song) {
    print("rebuild");
    this.song = song;
    loadTagList();
  }

  _loadFontConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String mail =
        (prefs.getString(Constants.sharedMail) ?? Constants.defaultMail);

    if (((fSize !=
                (prefs.getDouble(Constants.sharedDefaultFontSize) ??
                    Constants.initialFontSize)) &&
            previousfSize == null) ||
        _autoscroll !=
            (prefs.getBool(Constants.sharedAutoscroll) ??
                Constants.initialAutoscroll) ||
        _noteColor !=
            Color((prefs.getInt(Constants.sharedFontColor) ??
                Constants.initialColor)) ||
        _fontFamily !=
            (prefs.getString(Constants.sharedFontStyle) ??
                Constants.initialFontStyle)) {
      setState(() {
        fSize = (prefs.getDouble(Constants.sharedDefaultFontSize) ??
            Constants.initialFontSize);

        _autoscroll = (prefs.getBool(Constants.sharedAutoscroll) ??
            Constants.initialAutoscroll);

        _noteColor = Color((prefs.getInt(Constants.sharedFontColor) ??
            Constants.initialColor));

        _fontFamily = (prefs.getString(Constants.sharedFontStyle) ??
            Constants.initialFontStyle);

        _speed = (prefs.getDouble(Constants.sharedAutoscrollSpeed) ??
            Constants.initialAutoscrollSpeed);

        if (mail != Constants.defaultMail) {
          _logged = true;
        } else {
          _logged = false;
        }

        _runScroller();
      });
    }
  }

  _runScroller() {
    if (_autoscroll && _speed > 0) {
      _controller.animateTo(_songLength * fSize,
          curve: Curves.linear,
          duration: Duration(
              milliseconds: ((Constants.maxScrollSpeed - _speed) *
                      Constants.scrollMultiplier *
                      _songLength *
                      fSize)
                  .floor()));
    } else {
      _controller.animateTo(_controller.offset,
          curve: Curves.linear, duration: Duration(milliseconds: 1));
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controllerReportDesc = new TextEditingController(text: "");
    _loadFontConfiguration();
  }

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      //_selectedChoice = choice;
      if (choice.action != null) {
        choice.action(context);
      }
    });
  }

  _buildFloatButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: !_logged
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSongText(song: this.song),
                ),
              );
            },
      tooltip: !_logged ? AppLocalizations.of(context).login_needed : AppLocalizations.of(context).edit,
      child: Icon(Icons.edit),
      backgroundColor: !_logged ? Colors.grey : Theme.of(context).primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    choices = <Choice>[
      Choice(
          title: AppLocalizations.of(context).settings,
          icon: Icons.settings,
          action: (context) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SettingsStateful(title: AppLocalizations.of(context).settings)),
            );
          }),
    ];
    _loadFontConfiguration();
    Screen.keepOn(true);
    return Scaffold(
      appBar: AppBar(
        title: Text(this.song.title),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              String url =
                  Constants.urlPathSong + "?id=" + this.song.id.toString();
              Share.share(AppLocalizations.of(context).here_song_text + url);
            },
          ),
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: ListTile(
                      leading: Icon(choice.icon),
                      title: Text(choice.title),
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: _buildSong(context),
      floatingActionButton: _autoscroll
          ? Container(
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: FlutterSlider(
                          trackBar: FlutterSliderTrackBar(
                            activeTrackBarColor:
                                Theme.of(context).primaryColorLight,
                            activeTrackBarHeight: 5,
                            leftInactiveTrackBarColor: Colors.grey.shade200,
                          ),
                          values: [_speed],
                          min: 0,
                          max: Constants.maxScrollSpeed,
                          rtl: true,
                          axis: Axis.vertical,
                          handler: FlutterSliderHandler(
                            child: Material(
                              type: MaterialType.circle,
                              color: Theme.of(context).primaryColor,
                              elevation: 3,
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Icon(
                                  Constants.autoscrollIcon,
                                  //Icons.play_arrow,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          onDragging: (handlerIndex, lowerValue, upperValue) =>
                              {
                                setState(() {
                                  _speed = lowerValue;
                                  print("VELOCITA: " + _speed.toString());
                                  _runScroller();
                                })
                              }),
                    ),
                  ),
                  _buildFloatButton(context),
                ],
              ))
          : _buildFloatButton(context),
    );
  }

  /*
  double _calcWidth(String text) {
    RenderParagraph rp = RenderParagraph(
      TextSpan(
          style: new TextStyle(
              fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
          text: text),
      textDirection: TextDirection.ltr,
    );

    return rp.getMinIntrinsicWidth(18);
  }*/

  printD(String s) {
    print(s);
  }

  double sumSpace(String text, Map<String, double> charset) {
    double sum = 0;
    text.split("").forEach((d) {
      if (charset.containsKey(d)) {
        sum += charset[d];
      } else {
        sum += 1.0;
        print("Correggo per: " + d);
      }
    });
    return sum;
  }

  String space(String text, String chords, String chord, String prevChord) {
    printD("Lavoro con il font: " + _fontFamily);
    double sum = sumSpace(text, Charset.getFont(_fontFamily));
    double def = sumSpace(prevChord, Charset.getFontBold(_fontFamily));
    printD("Sum :" + sum.toString() + " def: " + def.toString());
    printD(text);
    printD(chord);
    printD(prevChord);
    sum -= def;
    printD("Occorrono: " + sum.toString() + " spazi");
    int i = 1;
    while (i < sum.round()) {
      chords += " ";
      i++;
    }

    //Add padding on chords if they are too close each other
    if ((chords != null) &&
        (chords.length > 0) &&
        (chords[chords.length - 1] != " ")) {
      chords += " ";
    }
    chords += chord;
    return chords;
  }

  List<Widget> _buildSongChordRow(String row) {
    List<Widget> resp = new List<Widget>();
    String chord = "";
    String text = row;
    Iterable<Match> matches = expChord.allMatches(row);
    int prevP = 0;
    String prevChord = "";
    for (Match m in matches) {
      String match = m.group(0);
      int p = text.indexOf(match);
      text = text.replaceFirst(match, "");
      match = match.substring(1, match.length - 1);
      chord = space(text.substring(prevP, p), chord, match, prevChord);
      prevP = p;
      prevChord = match;
    }

    resp.add(Text(
      chord,
      style: new TextStyle(
          fontSize: fSize,
          fontWeight: FontWeight.bold,
          fontStyle: fStyle,
          color: _noteColor,
          fontFamily: _fontFamily),
      //style: new TextStyle(fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
      overflow: TextOverflow.ellipsis,
    ));
    resp.add(Text(
      text,
      style: new TextStyle(
          fontSize: fSize,
          fontWeight: fWeight,
          fontStyle: fStyle,
          fontFamily: _fontFamily),
    ));
    return resp;
  }

  List<Widget> _buildSongRow(String row) {
    printD("**: " + row.length.toString());
    List<Widget> resp = new List<Widget>();
    if (expComment.hasMatch(row)) {
      printD("Commenti");
      if (expCommentL.hasMatch(row)) {
        printD("Commenti con annotazione");
        Match m = expCommentL.firstMatch(row);
        if (m.groupCount > 1) {
          String head = m.group(1);
          String tail = m.group(2);
          var fStyleEdit = fStyle;
          var fWeightEdit = fWeight;
          if (head == "author") {
            fStyleEdit = FontStyle.italic;
          } else {
            fWeightEdit = FontWeight.bold;
          }

          resp.add(Text(
            tail,
            style: new TextStyle(
                fontSize: fSize,
                fontWeight: fWeightEdit,
                fontStyle: fStyleEdit,
                fontFamily: _fontFamily),
          ));
        }
      } else {
        printD("Commenti senza annotazione");
        if (expInlineChorus.hasMatch(row)) {
          Match m = expInlineChorus.firstMatch(row);
          if (m.groupCount > 1) {
            String body = m.group(2);
            resp.add(Text(
              "",
              style:
                  new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
            ));
            if (expChord.hasMatch(body)) {
              fStyle = FontStyle.italic;
              printD("accordo");
              resp.addAll(_buildSongChordRow(body));
              fStyle = FontStyle.normal;
            } else {
              resp.add(Text(
                body,
                style: new TextStyle(
                    fontSize: fSize,
                    fontStyle: FontStyle.italic,
                    fontFamily: _fontFamily),
              ));
            }
            resp.add(Text(
              "",
              style:
                  new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
            ));
          }
        } else {
          printD("ritornello inlinea");
          Match m = expComment.firstMatch(row);
          if (m.groupCount >= 1) {
            String head = m.group(1);
            if (head == "soc") {
              //TODO: impostare bold
              resp.add(Text(
                "",
                style: new TextStyle(fontSize: fSize),
              ));
              fStyle = FontStyle.italic;
            }
            if (head == "eoc") {
              //TODO: impostare bold
              resp.add(Text(
                "",
                style: new TextStyle(
                    fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
              ));
              fStyle = FontStyle.normal;
            }
          }
        }
      }
    } else {
      printD("not commento");
      if (expChord.hasMatch(row)) {
        printD("accordo");
        resp.addAll(_buildSongChordRow(row));
      } else {
        printD("Altro ignoto");
        resp.add(Text(
          row,
          style: new TextStyle(
              fontSize: fSize,
              fontWeight: fWeight,
              fontStyle: fStyle,
              fontFamily: _fontFamily),
        ));
      }
    }
    return resp;
  }

  Widget _buildSong(BuildContext context) {
    w = new List<Widget>();

    List<String> q = this.song.body.split("\n");

    /*q.forEach((e) => w.add(Text(
          e,
          style: new TextStyle(fontSize: fSize),
        )));*/
    q.forEach((e) => w.addAll(_buildSongRow(e)));

    _songLength = w.length;
    if (this.song.tags.isNotEmpty) {
      w.add(Divider());
      w.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          AppLocalizations.of(context).tags+":",
          style: new TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.normal),
        ),
      ));

      List<Widget> _tags = new List<Widget>();
      this.song.tags.forEach((t) {
        _tags.add(
          RaisedButton(
            //elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Theme.of(context).primaryColorLight,
            child: Text(
              "#" + t.tag,
              style: new TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.normal,
                //color: Colors.white
              ),
            ),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate.builder(t.tag),
              );
            },
          ),
        );
      });
      w.add(
        Wrap(
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 4.0,
          children: _tags,
        ),
      );
    }

    w.add(Divider());

    w.add(
      Row(
        children: [
          Expanded(
            child: Ink(
              decoration: ShapeDecoration(
                color: Theme.of(context).primaryColor,
                shape: CircleBorder(),
              ),
              child: IconButton(
                color: Colors.white,
                icon: Icon(Icons.playlist_add),
                iconSize: 30.0,
                tooltip: AppLocalizations.of(context).add_to_playlist,
                padding: EdgeInsets.all(15.0),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChoosePlaylistStateful(
                            title: AppLocalizations.of(context).text_title, song: this.song)),
                  );
                },
              ),
            ),
          ),
          /*Expanded(
            child: Ink(
              decoration: ShapeDecoration(
                color: Theme.of(context).primaryColorDark,
                shape: CircleBorder(),
              ),
              child: IconButton(
                color: Colors.white,
                icon: Icon(Icons.add_photo_alternate),
                iconSize: 30.0,
                tooltip: AppLocalizations.of(context).multimedia,
                padding: EdgeInsets.all(15.0),
                onPressed: () {},
              ),
            ),
          ),*/
          Expanded(
            child: Ink(
              decoration: ShapeDecoration(
                color: Theme.of(context).errorColor,
                shape: CircleBorder(),
              ),
              child: IconButton(
                color: Colors.white,
                icon: Icon(Icons.report),
                iconSize: 30.0,
                tooltip: AppLocalizations.of(context).abuse,
                padding: EdgeInsets.all(15.0),
                onPressed: () {
                  _showReportDialog(context);
                },
              ),
            ),
          ),
        ],
      ),
    );

    w.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: const Text(''),
    ));

    return new GestureDetector(
      onScaleStart: (scaleDetails) => setState(() => previousfSize = fSize),
      onScaleUpdate: (ScaleUpdateDetails scaleDetails) {
        setState(() {
          fSize = previousfSize * scaleDetails.scale;
        });
      },
      child: ListView(
        controller: _controller,
        shrinkWrap: true,
        padding: const EdgeInsets.all(20.0),
        children: w,
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
    _controller.dispose();
    _controllerReportDesc.dispose();
  }

  _buildReportOptionsList() {
    List<DropdownMenuItem<String>> l = new List<DropdownMenuItem<String>>();
    List f = Constants.reportOption;
    f.forEach((value) => {
          l.add(DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: new TextStyle(fontFamily: value)),
          ))
        });
    return l;
  }

  void _showReportDialog(BuildContext contextOld) {
    showDialog(
      context: contextOld,
      builder: (BuildContext context) {
        // return object of type Dialog
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: new Text(AppLocalizations.of(context).abuse_title),
              content: Container(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(AppLocalizations.of(context).abuse_desc),
                        onChanged: (String newValue) {
                          print(newValue);
                          setState(() {
                            reportValue = newValue;
                            print(reportValue);
                          });
                        },
                        value: reportValue,
                        items: _buildReportOptionsList(),
                      ),
                    ),
                    new ListTile(
                      title: TextField(
                        maxLines: 4,
                        textAlign: TextAlign.left,
                        controller: _controllerReportDesc,
                        decoration: InputDecoration(
                          labelText: 'Descrizione:',
                        ),
                      ),
                    ),
                  ],
                  //new Text("Selezione la ragione adeguata:"),
                ),
              ),
              actions: <Widget>[
                new FlatButton(
                  child: new Text(
                    AppLocalizations.of(context).undo,
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                new FlatButton(
                  child: new Text(AppLocalizations.of(context).send),
                  onPressed: () {
                    reportSong();

                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  reportSong() async{
    await Updater.reportSong(song, Constants.reportOption.indexOf(reportValue), _controllerReportDesc.text);
  }
}
