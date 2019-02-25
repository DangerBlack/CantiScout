import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


import 'model/Song.dart';
import 'model/Tag.dart';


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
              "idSong INTEGER NOT NULL UNIQUE"
              ")");

          await db.execute("CREATE TABLE Tag ("
              "id INTEGER PRIMARY KEY,"
              "idSong INTEGER NOT NULL,"
              "tag TEXT NOT NULL"
              ")");
        });
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;

    print("Loading Songs!");
    // var res = await db.rawQuery("SELECT * FROM Client WHERE blocked=1");
    //var res = await db.query("Song", where: "blocked = ? ", whereArgs: [1]);
    var res = await db.query("Song",orderBy: "title");

    List<Song> list =
    res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    return list;
  }

  Future<List<Song>> getSongs(String search) async {
    final db = await database;

    print("Loading Songs Filtered!");
    // var res = await db.rawQuery("SELECT * FROM Client WHERE blocked=1");
    //var res = await db.query("Song", where: "blocked = ? ", whereArgs: [1]);
    search = "%"+search+"%";
    //var res = await db.query("Song",  where: "title LIKE ? or author LIKE ? or body LIKE ?", whereArgs: [search,search,search]);
    var res = await db.rawQuery("SELECT * FROM  Song as s join Tag as t on s.id = t.idSong where s.title LIKE ? or s.author LIKE ? or s.body LIKE ? or t.tag LIKE ? GROUP BY s.id", [search,search,search,search]);

    List<Song> list =
    res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    return list;
  }

  Future<List<String>> getSongsTitle(String search) async {
    List<String> res=new List<String>();
    List<Song> list = await getSongs(search);
    list.forEach((song){
      res.add(song.title);
    });
    return res;
  }

  newSong(Song song) async {
    final db = await database;
    /*var raw = await db.rawInsert(
        "INSERT Into Song (id,title,author,time,body)"
            " VALUES (?,?,?,?)",
        [song.id,song.title,song.author,song.time,song.body]);*/
    var raw = await db.insert("Song",song.toMap());
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
    bool t = await hasSong(song.id);
    if(t){
      return await updateSong(song);
    }else{
      return await newSong(song);
    }
  }

  Future<List<Tag>> getTagsBySongId(int idSong) async {
    final db = await database;
    var res = await db.query("Tag", where: "idSong = ?", whereArgs: [idSong]);

    List<Tag> list =
    res.isNotEmpty ? res.map((c) => Tag.fromMap(c)).toList() : [];
    return list;
  }

  getLastDate() async {
    final db = await database;
    var res = await db.rawQuery("SELECT  MAX(time) AS max FROM Song");
    return res.isNotEmpty ? res.first['max'] : null;
  }

  newTag(Tag tag) async {
    final db = await database;
    /*var raw = await db.rawInsert(
        "INSERT Into Song (id,title,author,time,body)"
            " VALUES (?,?,?,?)",
        [song.id,song.title,song.author,song.time,song.body]);*/
    var raw = await db.insert("Tag",tag.toMap());
    return raw;
  }
}