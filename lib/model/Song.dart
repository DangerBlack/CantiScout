import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'Tag.dart';

Song songFromJson(String str) {
  final jsonData = json.decode(str) as Map<String, dynamic>;
  return Song.fromMap(jsonData);
}

String songToJson(Song data) {
  return json.encode(data.toMap());
}

class Song {
  String id;
  String title;
  String? author;
  String time;
  String body;
  int status;
  String? username;

  List<Tag> tags = [];

  Song({
    required this.id,
    required this.title,
    this.author,
    required this.time,
    required this.body,
    this.status = 0,
    this.username,
  });

  /// Create a brand-new song with a generated UUID and current timestamp.
  factory Song.create({
    required String title,
    String? author,
    required String body,
    String? username,
  }) {
    return Song(
      id: const Uuid().v4(),
      title: title,
      author: author,
      time: DateTime.now().toIso8601String(),
      body: body,
      status: 0,
      username: username,
    );
  }

  factory Song.fromMap(Map<String, dynamic> json) => Song(
        id: json['id']?.toString() ?? const Uuid().v4(),
        title: _ucfirst(json['title']?.toString() ?? ''),
        author: json['author'] != null && json['author'].toString().isNotEmpty
            ? _ucfirst(json['author'].toString())
            : null,
        time: json['time']?.toString() ?? DateTime.now().toIso8601String(),
        body: json['body']?.toString() ?? '',
        status: json['status'] != null
            ? int.tryParse(json['status'].toString()) ?? 0
            : 0,
        username: json['username']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author ?? '',
        'time': time,
        'body': body,
        'status': status,
        'username': username ?? '',
      };

  void setTags(List<Tag> tags) {
    this.tags = tags;
  }

  static String _ucfirst(String s) {
    s = s.trim();
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
