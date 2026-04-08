import 'dart:convert';

Tag tagFromJson(String str) {
  final jsonData = json.decode(str) as Map<String, dynamic>;
  return Tag.fromMap(jsonData);
}

String tagToJson(Tag data) {
  return json.encode(data.toMap());
}

class Tag {
  int id;
  String idSong; // UUID of the parent song
  String tag;

  Tag({
    required this.id,
    required this.idSong,
    required this.tag,
  });

  factory Tag.fromMap(Map<String, dynamic> json) => Tag(
        id: int.tryParse(json['id'].toString()) ?? 0,
        idSong: json['idSong']?.toString() ?? '',
        tag: json['tag']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'idSong': idSong,
        'tag': tag,
      };
}
