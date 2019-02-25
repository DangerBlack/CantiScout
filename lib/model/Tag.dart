import 'dart:convert';

Tag tagFromJson(String str) {
  final jsonData = json.decode(str);
  return Tag.fromMap(jsonData);
}

String tagToJson(Tag data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Tag {
  int id;
  int idSong;
  String tag;

  Tag({
    this.id,
    this.idSong,
    this.tag,
  });

  factory Tag.fromRemoteMap(Map<String, dynamic> json) => new Tag(
      id: int.parse(json["id"].toString()),
      idSong: int.parse(json["id_song"].toString()),
      tag: json["tag"],
  );

  factory Tag.fromMap(Map<String, dynamic> json) => new Tag(
      id: int.parse(json["id"].toString()),
      idSong: int.parse(json["idSong"].toString()),
      tag: json["tag"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "idSong": idSong,
    "tag": tag,
  };
}