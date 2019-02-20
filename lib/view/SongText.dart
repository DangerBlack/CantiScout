import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../model/Song.dart';

import '../model/SongList.dart';
import '../FirstRoute.dart';

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
  SongTextState createState() => SongTextState(song: this.song);
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

  SongTextState({this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.song.title),
      ),
      body: _buildSong(context),
    );
  }

  double _calcWidth(String text) {
    RenderParagraph rp = RenderParagraph(
      TextSpan(style: new TextStyle(fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle), text: text),
      textDirection: TextDirection.ltr,
    );

    return rp.getMinIntrinsicWidth(18);
  }
  Map<String, double> charset = {
    "a": 2.5,
    "b": 2.0,
    "c": 2.0,
    "d": 2.0,
    "e": 2.0,
    "f": 1.2,
    "g": 2.0,
    "h": 2.0,
    "i": 1.2,
    "l": 1.0,
    "j": 1.0,
    "k": 2.0,
    "m": 3.75,
    "n": 2.0,
    "o": 2.0,
    "p": 1.9,
    "q": 2.0,
    "r": 1.5,
    "s": 2.0,
    "t": 1.5,
    "u": 2.0,
    "v": 2.0,
    "w": 2.0,
    "x": 2.0,
    "y": 2.0,
    "z": 2.0,
    "A": 3.0,
    "B": 3.0,
    "C": 3.0,
    "D": 3.0,
    "E": 3.0,
    "F": 3.0,
    "G": 3.0,
    "H": 1.8,
    "I": 3.0,
    "L": 3.0,
    "J": 3.0,
    "K": 3.0,
    "M": 4.0,
    "N": 3.0,
    "O": 3.0,
    "P": 3.0,
    "Q": 3.0,
    "R": 3.0,
    "S": 3.0,
    "T": 3.0,
    "U": 3.0,
    "V": 3.0,
    "W": 3.0,
    "X": 3.0,
    "Y": 3.0,
    "Z": 3.0,
    " ": 1.0,
    "'": 1.0,
    "-": 2.0,
    "1": 1.0,
    "2": 2.0,
    "3": 2.0,
    "4": 3.0,
    "5": 3.0,
    "6": 3.0,
    "7": 3.0,
    "8": 3.0,
    "9": 3.0,
    "è": 3.0,
    "à": 3.0,
    "ì": 1.2,
    "é": 3.0,
    "ù": 3.0,
    ".": 1.0,
  };
  double sumSpace(String text){
    double sum = 0;
    text.split("").forEach((d){
      if(charset.containsKey(d)) {
        sum += charset[d];
      }else{
        sum += 1.0;
        print("Correggo per: "+d);
      }
    });
    return sum;
  }

  String space(String text, String chords,String chord, String prevChord){
      int a = chords.length;
      int b = text.length;
      /*while(a<b*1.55){
        a = chords.length;
        chords+="  ";
      }*/
      double sum = sumSpace(text);
      double def = sumSpace(prevChord);
      sum-=def;
      int i=0;
      while(i<sum){
        chords+=" ";
        i++;
      }

      chords+=chord;
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
      match = match.substring(1,match.length-1);
      chord = space(text.substring(prevP,p),chord,match,prevChord);
      prevP = p;
      prevChord = match;
    }

    resp.add(Text(
      chord,
      style: new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold, fontStyle: fStyle),
      overflow: TextOverflow.ellipsis ,
    ));
    resp.add(Text(
      text,
      style: new TextStyle(fontSize: fSize, fontWeight: fWeight, fontStyle: fStyle),
    ));
    return resp;
  }

  List<Widget> _buildSongRow(String row) {
    List<Widget> resp = new List<Widget>();
    if (expComment.hasMatch(row)) {
      if (expCommentL.hasMatch(row)) {
        Match m = expCommentL.firstMatch(row);
        if (m.groupCount > 1) {
          String head = m.group(1);
          String tail = m.group(2);
          resp.add(Text(
            tail,
            style: new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
          ));
        }
      } else {
        if (expInlineChorus.hasMatch(row)) {
          Match m = expInlineChorus.firstMatch(row);
          if (m.groupCount > 1) {
            String body = m.group(2);
            resp.add(Text(
              "",
              style:
                  new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
            ));
            resp.add(Text(
              body,
              style:
                  new TextStyle(fontSize: fSize, fontStyle: FontStyle.italic),
            ));
            resp.add(Text(
              "",
              style:
                  new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
            ));
          }
        } else {
          Match m = expComment.firstMatch(row);
          if (m.groupCount >= 1) {
            String head = m.group(1);
            if (head == "soc") {
              //TODO: impostare bold
              resp.add(Text(
                "",
                style:
                    new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
              ));
              fStyle = FontStyle.italic;
            }
            if (head == "eoc") {
              //TODO: impostare bold
              resp.add(Text(
                "",
                style:
                    new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
              ));
              fStyle = FontStyle.normal;
            }
          }
        }
      }
    }else {
      if (expChord.hasMatch(row)) {
        resp.addAll(_buildSongChordRow(row));
      }else{
        resp.add(Text(
          "",
          style:
          new TextStyle(fontSize: fSize, fontWeight: FontWeight.bold),
        ));
      }
    }
    return resp;
  }

  Widget _buildSong(BuildContext context) {
    List<Widget> w = new List<Widget>();

    List<String> q = this.song.body.split("\r\n");

    /*q.forEach((e) => w.add(Text(
          e,
          style: new TextStyle(fontSize: fSize),
        )));*/
    q.forEach((e) => w.addAll(_buildSongRow(e)));

    return new GestureDetector(
      onScaleStart: (scaleDetails) => setState(() => previousfSize = fSize),
      onScaleUpdate: (ScaleUpdateDetails scaleDetails) {
        setState(() {
          fSize = previousfSize * scaleDetails.scale;
        });
      },
      child: ListView(
          shrinkWrap: true, padding: const EdgeInsets.all(20.0), children: w),
    );
  }
}
