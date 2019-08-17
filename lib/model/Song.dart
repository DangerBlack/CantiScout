import 'dart:convert';
import 'Tag.dart';

Song songFromJson(String str) {
  final jsonData = json.decode(str);
  return Song.fromMap(jsonData);
}

String songToJson(Song data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Song{
  int id;
  String title;
  String author;
  String time;
  String body;
  int status;

  List<Tag> tags = new List<Tag>();

  Song({
    this.id,
    this.title,
    this.author,
    this.time,
    this.body,
    this.status,
  });

  factory Song.fromMap(Map<String, dynamic> json) => new Song(
    id: int.parse(json["id"].toString()),
    title: ucfirst(json["title"]),
    author: ucfirst(json["author"]),
    time: json["time"],
    body: json["body"],
    status: int.parse(json["status"].toString())
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "title": title,
    "author": safe(author),
    "time": time,
    "body": body,
    "status": status,
  };

  List toDb(){
    return [this.id,this.title,safe(this.author),this.time,this.body,this.status];
  }

  setTags(List<Tag> tags){
    this.tags = tags;
  }


  static ucfirst(String s)
  {
    s = s.trim();
    if(s.length <= 0)
      return s;

    return s[0].toUpperCase() + s.substring(1);
  }

  static safe(Object x)
  {
    if(x != null)
      return x;

    return "";
  }
}