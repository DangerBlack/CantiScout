import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share/share.dart';

import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';
import '../model/Chartset.dart';
import '../Database.dart';
import '../controller/CustomSearchDelegate.dart';
import '../view/ChoosePlaylist.dart';

class SongText extends StatefulWidget {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  Song song;
  int numberOfDays = 31;
  int previousNumOfDays;

/*  SongText({
    this.song
  });*/

  SongText({Key key, this.song}) : super(key: key);

  @override
  SongTextState createState() => SongTextState(this.song);
}

class SongTextState extends State {

  final RegExp expChord = new RegExp(r"\[([^\]]*)\]");
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

  Song song;
  double fSize = 18.0;
  FontWeight fWeight = FontWeight.normal;
  FontStyle fStyle = FontStyle.normal;

  int numberOfDays = 31;
  double previousfSize;

  List<Widget> w = new List<Widget>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.song.title),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              String url = Constants.urlPathSong + "?id=" +
                  this.song.id.toString();
              Share.share('Ecco il testo della canzone ' + url);
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {

            },
          ),
        ],
      ),
      body: _buildSong(context),
      floatingActionButton: FloatingActionButton(
        //onPressed: _incrementCounter,
        tooltip: 'Edit',
        child: Icon(Icons.edit),
      ),
    );
  }

  double _calcWidth(String text) {
    RenderParagraph rp = RenderParagraph(
      TextSpan(
          style: new TextStyle(
              fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
          text: text),
      textDirection: TextDirection.ltr,
    );

    return rp.getMinIntrinsicWidth(18);
  }

  printD(String s) {
    //print(s);
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
    double sum = sumSpace(text, Charset.robotoRegular);
    double def = sumSpace(prevChord, Charset.robotoBold);
    printD("Sum :" + sum.toString() + " def: " + def.toString());
    printD(text);
    printD(chord);
    printD(prevChord);
    sum -= def;
    printD("Occorrono: " + sum.toString() + " spazi");
    int i = 1;
    while (i < sum) {
      chords += " ";
      i++;
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
          fontSize: fSize, fontWeight: FontWeight.bold, fontStyle: fStyle),
      //style: new TextStyle(fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
      overflow: TextOverflow.ellipsis,
    ));
    resp.add(Text(
      text,
      style: new TextStyle(
          fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
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
                fontStyle: fStyleEdit),
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
                style:
                new TextStyle(fontSize: fSize, fontStyle: FontStyle.italic),
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
              fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
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


    if (this.song.tags.isNotEmpty) {
      w.add(Divider());
      w.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Tags:',
          style: new TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal),
        ),
      ));

      List<Widget> _tags = new List<Widget>();
      this.song.tags.forEach((t) {
        _tags.add(RaisedButton(
          child: Text(
            "#" + t.tag,
            style: new TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal),
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
      Ink(
        decoration: ShapeDecoration(
          color: Colors.green,
          shape: CircleBorder(),
        ),
        child: IconButton(
          color: Colors.white,
          icon: Icon(Icons.playlist_add),
          iconSize: 30.0,
          tooltip: "Aggiungi alla playlist",
          padding: EdgeInsets.all(15.0),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChoosePlaylistStateful(title:"Titolo", song: this.song)),
            );
          },
        ),
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
        shrinkWrap: true,
        padding: const EdgeInsets.all(20.0),
        children: w,
      ),
    );
  }
}
