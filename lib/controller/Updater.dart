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
  static Future<SongList> updateSongs([bool force=false]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastCheck = (prefs.getString(Constants.lastDateCheck) ??
        DateTime(1900).toIso8601String());
    print(lastCheck);
    DateTime lastCheckDate = DateTime.parse(lastCheck);
    if (force || DateTime.now().difference(lastCheckDate) >=
        Constants.waitBetweenCheck) {
      print("Check for update");
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
            print("Aggiorno pref");
            prefs.setString(
                Constants.lastDateCheck, DateTime.now().toIso8601String());
            return songs;
          } else {
            print("Aggiorno pref");
            prefs.setString(
                Constants.lastDateCheck, DateTime.now().toIso8601String());
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
        print(E.toString());
        print("Failed to load songs");
        return SongList();
      }
    } else {
      print("Not Checked!");
      return SongList();
    }
  }

  static String fromOptToTagList(List<bool> opt){
    String s="";
    for(int i=0;i<opt.length;i++){
        if(opt[i]){
          s+=Constants.optTag[i]+",";
        }
    }
    if(s.length>0){
      s.substring(0,s.length-1);
    }
    return s;
  }
  static Future<int> updateSong(Song song,List<bool> opt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(Constants.sharedToken);

    if (token != null) {
      try {
        Map<String, dynamic> s = song.toMap();
        s["token"] = token;

        String tokenAction = Constants.tokenUpdateSong;
        if (song.id == null || song.id == -1) {
          tokenAction = Constants.tokenNewSong;
          s["tag"] = fromOptToTagList(opt);
        }
        final response = await http.post(Constants.tokenApi + tokenAction,
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

          final jsonData = json.decode(response.body);
          print("Failed to upload songs [" +
              response.statusCode.toString() +
              "]");
          return jsonData['code'];
        }
      } catch (E) {
        //throw Exception('Failed to load songs');
        print("Failed to upload songs");
        return -30;
      }
    } else {
      print("No available token");
      return -40;
    }
  }

  static Future<int> expireToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(Constants.sharedToken);

    if (token != null) {
      try {
        Map<String, dynamic> s = new Map<String, dynamic>();
        s["token"] = token;
        final response = await http.post(
            Constants.tokenApi + Constants.tokenExpire,
            body: json.encode(s));

        print(response.request.url);
        if (response.statusCode == 204) {
          // If server returns an OK response, parse the JSON
          print(response.body);
          return 1;
        } else {
          print(response.body);
          print("Failed to expire token [" +
              response.statusCode.toString() +
              "]");
          return -2;
        }
      } catch (E) {
        //throw Exception('Failed to load songs');
        print("Failed to expire token");
        return -3;
      }
    } else {
      print("No available token");
      return -4;
    }
  }

  static Future<int> updatePswd(String oldPswd, String newPswd) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(Constants.sharedToken);

    if (token != null) {
      try {
        Map<String, dynamic> s = new Map<String, dynamic>();
        s["token"] = token;
        s["oldPswd"] = oldPswd;
        s["newPswd"] = newPswd;
        print(s);
        final response = await http.post(
            Constants.tokenApi + Constants.updatePassword,
            body: json.encode(s));

        print(response.request.url);
        if (response.statusCode == 201) {
          // If server returns an OK response, parse the JSON
          print(response.body);
          return 1;
        } else {
          print(response.body);
          print("Failed to change password token [" +
              response.statusCode.toString() +
              "]");
          return -2;
        }
      } catch (E) {
        //throw Exception('Failed to load songs');
        print("Failed to expire token");
        return -3;
      }
    } else {
      print("No available token");
      return -4;
    }
  }

  static Future<int> reportSong(Song song, int kind, String description) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(Constants.sharedToken);

    if (token != null) {
      try {
        Map<String, dynamic> s = new Map<String, dynamic>();
        s["token"] = token;
        s["idSong"] = song.id;
        s["description"] = description;
        s["kind"] = kind;
        print(s);
        final response = await http.post(Constants.tokenApi + Constants.report,
            body: json.encode(s));

        print(response.request.url);
        if (response.statusCode == 201) {
          // If server returns an OK response, parse the JSON
          print(response.body);
          return 1;
        } else {
          print(response.body);
          print("Failed to change password token [" +
              response.statusCode.toString() +
              "]");
          return -2;
        }
      } catch (E) {
        //throw Exception('Failed to load songs');
        print("Failed to expire token");
        return -3;
      }
    } else {
      print("No available token");
      return -4;
    }
  }
}
