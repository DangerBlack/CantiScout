import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

//import 'package:sqflite/sqflite.dart';
import '../Database.dart';
import '../model/SongList.dart';
import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';

class Updater {
  /// Update the database retrieving from website the list of the new song.
  /// Returns The song list retrieved from the remote address.
  static Future<SongList> updateSongs() async {
    String max = await DBProvider.db.getLastDate();
    if (max == null) {
      max = "";
    }
    print("Time max:" + max);
    max = Uri.encodeFull(max);
    try {
      final response = await http.get(Constants.urlPathSongList + max);

      if (response.statusCode == 200) {
        // If server returns an OK response, parse the JSON
        print(response.body);
        if (response.body != "204") {
          final jsonData = json.decode(response.body);
          print(jsonData['songlist'][0]['title']);

          var myThing = (json.decode(response.body)['songlist'] as List)
              .map((e) => new Song.fromMap(e))
              .toList();
          print(myThing[0].title);
          SongList songs = new SongList();
          songs.list = myThing;
          songs.list.forEach((s) {
            DBProvider.db.updateOrInsertSong(s);
          });

          var tags = (json.decode(response.body)['taglist'] as List)
              .map((e) => new Tag.fromRemoteMap(e))
              .toList();

          tags.forEach((t) {
            DBProvider.db.newTag(t);
          });
          return songs;
        }
        return SongList();
      } else {
        // If that response was not OK, throw an error.
        //throw Exception('Failed to load songs');
        print("Failed to load songs");
        return SongList();
      }
    } catch (E) {
      //throw Exception('Failed to load songs');
      print("Failed to load songs");
      return SongList();
    }
  }

  static Future<int> updateSong(Song song) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(Constants.sharedToken);

    if (token != null) {
      try {
        Map<String, dynamic> s = song.toMap();
        s["token"] = token;
        final response = await http.post(
            Constants.tokenApi + Constants.tokenMewSong,
            body: json.encode(s));

        print(response.request.url);
        if (response.statusCode == 201) {
          // If server returns an OK response, parse the JSON
          print(response.body);
          return 1;
        } else {
          print(response.body);
          // If that response was not OK, throw an error.
          //throw Exception('Failed to load songs');
          print("Failed to upload songs ["+response.statusCode.toString()+"]");
          return -2;
        }
      } catch (E) {
        //throw Exception('Failed to load songs');
        print("Failed to upload songs");
        return -3;
      }
    }else{
      print("No available token");
      return -4;
    }
  }
}
