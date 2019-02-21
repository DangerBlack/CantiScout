import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


import 'model/Song.dart';


// Database guide
// https://github.com/Rahiche/sqlite_demo/tree/master/lib
class DBProvider {
  static final String dbName = "CantiScout.db";

  DBProvider._();
  static final DBProvider db = DBProvider._();
  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {

          await db.execute("CREATE TABLE Song ("
            "id INTEGER PRIMARY KEY,"
            "title TEXT NOT NULL,"
            "author TEXT,"
            "time TIMESTAMP NOT NULL,"
            "body TEXT NOT NULL"
            ")");

          await db.execute("CREATE TABLE favourite ("
              "id INTEGER PRIMARY KEY,"
              "id_song INTEGER NOT NULL UNIQUE"
              ")");

          await db.execute("CREATE TABLE tag ("
              "id INTEGER PRIMARY KEY,"
              "id_song INTEGER NOT NULL,"
              "tag TEXT NOT NULL"
              ")");
        });
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;

    print("Loading Songs!");
    // var res = await db.rawQuery("SELECT * FROM Client WHERE blocked=1");
    //var res = await db.query("Song", where: "blocked = ? ", whereArgs: [1]);
    var res = await db.query("Song");

    List<Song> list =
    res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    return list;
  }

  newSong(Song song) async {
    final db = await database;
    var raw = await db.rawInsert(
        "INSERT Into Client (id,title,author,time,body)"
            " VALUES (?,?,?,?)",
        song.toDb());
    return raw;
  }

  updateSong(Song song) async {
    final db = await database;
    var res = await db.update("Song", song.toMap(),
        where: "id = ?", whereArgs: [song.id]);
    return res;
  }

  getSong(int id) async {
    final db = await database;
    var res = await db.query("Song", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Song.fromMap(res.first) : null;
  }

  hasSong(int id) async {
    final db = await database;
    var res = await db.query("Song", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty;
  }

  updateOrInsertSong(Song song) async{
    if(hasSong(song.id)){
      updateSong(song);
    }else{
      newSong(song);
    }
  }

  getLastDate() async {
    final db = await database;
    var res = await db.query("SELECT MAX(time) AS max FROM song");
    return res.isNotEmpty ? res.first['max'] : null;
  }
}