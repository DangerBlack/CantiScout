import 'dart:convert';

Playlist playlistFromJson(String str) {
  final jsonData = json.decode(str);
  return Playlist.fromMap(jsonData);
}

String playlistToJson(Playlist data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Playlist{
  int id;
  String title;
  int idUser;
  String permission;
  String time;
  int songCount;

  Playlist({
    this.id,
    this.title,
    this.idUser,
    this.permission,
    this.time,
    this.songCount
  });

  factory Playlist.fromMap(Map<String, dynamic> json) => new Playlist(
      id: int.parse(json["id"].toString()),
      title: json["title"],
      idUser: int.parse(json["idUser"].toString()),
      time: json["time"].toString(),
      permission: json["permission"].toString(),
      songCount: json["songCount"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "title": title,
    "idUser": idUser,
    "time": time,
    "permission": permission,
    "songCount": songCount,
  };
}