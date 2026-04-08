import 'dart:convert';

Playlist playlistFromJson(String str) {
  final jsonData = json.decode(str) as Map<String, dynamic>;
  return Playlist.fromMap(jsonData);
}

String playlistToJson(Playlist data) {
  return json.encode(data.toMap());
}

class Playlist {
  int id;
  String title;
  String time;
  int songCount;

  Playlist({
    this.id = 0,
    this.title = '',
    this.time = '',
    this.songCount = 0,
  });

  factory Playlist.fromMap(Map<String, dynamic> json) => Playlist(
        id: int.tryParse(json['id'].toString()) ?? 0,
        title: json['title']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        songCount: json['songCount'] != null
            ? int.tryParse(json['songCount'].toString()) ?? 0
            : 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time,
        'songCount': songCount,
      };
}
