import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


import 'model/Song.dart';
import 'model/Playlist.dart';
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

          await db.execute("CREATE TABLE Playlist ("
              "id INTEGER PRIMARY KEY,"
              "title INTEGER NOT NULL UNIQUE,"
              "idUser INTEGER NOT NULL,"
              "permission INTEGER NOT NULL,"
              "time TIMESTAMP NOT NULL"
              ")");

          await db.execute("CREATE TABLE PlaylistSong ("
              "id INTEGER PRIMARY KEY,"
              "idPlaylist INTEGER NOT NULL,"
              "idSong INTEGER NOT NULL"
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
    var res = await db.rawQuery("SELECT s.id,s.title,s.author,s.time,s.body FROM  Song as s join Tag as t on s.id = t.idSong where s.title LIKE ? or s.author LIKE ? or s.body LIKE ? or t.tag LIKE ? GROUP BY s.id", [search,search,search,search]);

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
    var res = await db.query("Tag", where: "idSong = ? and (not tag is NULL) and (not tag = '')" , whereArgs: [idSong]);

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


  //Playlist

  Future<List<Playlist>> getAllPlaylist() async {
    final db = await database;

    print("Loading Playlist!");
    //var res = await db.query("Playlist",orderBy: "title");
    var res = await db.rawQuery("select p.id,p.title,p.idUser,p.permission,p.time, count(pl.id) as songCount FROM Playlist as p left join PlaylistSong as pl ON p.id = pl.idPlaylist GROUP BY p.id ORDER BY p.title");

    print(res);
    List<Playlist> list =
    res.isNotEmpty ? res.map((c) => Playlist.fromMap(c)).toList() : [];
    return list;
  }

  newPlaylist(String title) async {
    final db = await database;
    var raw = await db.rawInsert(
        "INSERT Into Playlist (title,idUser,permission,time)"
            " VALUES (?,?,?,?)",
        [title,0,0,new DateTime.now().millisecondsSinceEpoch]);
    return raw;
  }

  Future<List<Song>> getAllPlaylistSongs(int idPlaylist) async {
    final db = await database;

    print("Loading Songs!");
    // var res = await db.rawQuery("SELECT * FROM Client WHERE blocked=1");
    //var res = await db.query("Song", where: "blocked = ? ", whereArgs: [1]);

    //Siamo sicuri che l'ordine per titolo sia una buona idea, se sto organizzando i canti per la messa l'ordine è fondamentale!!!
    var res = await db.rawQuery("SELECT * FROM  Song as s join PlaylistSong as p on s.id = p.idSong WHERE p.idPlaylist = ? ORDER BY p.id ",[idPlaylist]);

    List<Song> list =
    res.isNotEmpty ? res.map((c) => Song.fromMap(c)).toList() : [];
    return list;
  }

  newSongPlaylist(Playlist pl, Song song) async {
    final db = await database;
    var raw = await db.rawInsert(
        "INSERT Into PlaylistSong (idPlaylist,idSong)"
            " VALUES (?,?)",
        [pl.id,song.id]);
    return raw;
  }

  newSongPlaylistRaw(int plID, int songID) async {
    final db = await database;
    var raw = await db.rawInsert(
        "INSERT Into PlaylistSong (idPlaylist,idSong)"
            " VALUES (?,?)",
        [plID,songID]);
    return raw;
  }
}