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

  List<Tag> tags = new List<Tag>();

  Song({
    this.id,
    this.title,
    this.author,
    this.time,
    this.body,
  });

  factory Song.fromMap(Map<String, dynamic> json) => new Song(
    id: int.parse(json["id"].toString()),
    title: json["title"],
    author: json["author"],
    time: json["time"],
    body: json["body"]
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "title": title,
    "author": author,
    "time": time,
    "body": body,
  };

  List toDb(){
    return [this.id,this.title,this.author,this.time,this.body];
  }

  setTags(List<Tag> tags){
    this.tags = tags;

  }
}