import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Database.dart';
import '../model/SongList.dart';
import '../model/Song.dart';


class Updater{

  static Future<SongList> updateSongs() async {
    final response =
    await http.get('https://512b.it/cantiscout/php/get.php');

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      print(response.body);
      final jsonData = json.decode(response.body);
      print(jsonData['songlist'][0]['title']);

      var myThing = (json.decode(response.body)['songlist'] as List).map((e) => new Song.fromMap(e)).toList();
      print(myThing[0].title);
      SongList songs = new SongList();
      songs.list = myThing;
      return songs;
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load songs');
    }
  }

}