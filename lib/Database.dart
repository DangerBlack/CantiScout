import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'model/Song.dart';
import 'model/Playlist.dart';
import 'model/Tag.dart';

class DBProvider {
  static const String dbName = "CantiScout.db";
  static const int _dbVersion = 4;

  // Upgrade scripts: key = new version
  static final Map<int, List<String>> _upgrades = {
    4: [
      // Clean break: drop all legacy tables and recreate with UUID-based Song IDs
      "DROP TABLE IF EXISTS PlaylistSong;",
      "DROP TABLE IF EXISTS Tag;",
      "DROP TABLE IF EXISTS Playlist;",
      "DROP TABLE IF EXISTS Song;",
      "CREATE TABLE Song ("
          "id TEXT PRIMARY KEY,"
          "title TEXT NOT NULL,"
          "author TEXT,"
          "time TIMESTAMP NOT NULL,"
          "body TEXT NOT NULL,"
          "status INTEGER NOT NULL DEFAULT 0,"
          "username TEXT"
          ");",
      "CREATE TABLE Playlist ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "title TEXT NOT NULL UNIQUE,"
          "time TIMESTAMP NOT NULL"
          ");",
      "CREATE TABLE PlaylistSong ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "idPlaylist INTEGER NOT NULL,"
          "idSong TEXT NOT NULL"
          ");",
      "CREATE TABLE Tag ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "idSong TEXT NOT NULL,"
          "tag TEXT NOT NULL"
          ");",
    ],
  };

  DBProvider._();
  static final DBProvider db = DBProvider._();
  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Song ("
            "id TEXT PRIMARY KEY,"
            "title TEXT NOT NULL,"
            "author TEXT,"
            "time TIMESTAMP NOT NULL,"
            "body TEXT NOT NULL,"
            "status INTEGER NOT NULL DEFAULT 0,"
            "username TEXT"
            ");");
        await db.execute("CREATE TABLE Playlist ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "title TEXT NOT NULL UNIQUE,"
            "time TIMESTAMP NOT NULL"
            ");");
        await db.execute("CREATE TABLE PlaylistSong ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "idPlaylist INTEGER NOT NULL,"
            "idSong TEXT NOT NULL"
            ");");
        await db.execute("CREATE TABLE Tag ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "idSong TEXT NOT NULL,"
            "tag TEXT NOT NULL"
            ");");
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        for (int v = oldVersion; v < newVersion; v++) {
          await _upgradeDb(db, v, v + 1);
        }
      },
    );
  }

  Future<void> _upgradeDb(
      Database db, int oldVersion, int newVersion) async {
    if (_upgrades.containsKey(newVersion)) {
      for (final String query in _upgrades[newVersion]!) {
        try {
          await db.execute(query);
        } catch (e) {
          // ignore errors on drop statements
        }
      }
    }
  }

  // ── Songs ──────────────────────────────────────────────────────────────────

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final res = await db.query('Song', where: 'status = 0', orderBy: 'title');
    return res.map((c) => Song.fromMap(c)).toList();
  }

  Future<List<Song>> getSongs(String search) async {
    final db = await database;
    final pattern = '%$search%';
    final res = await db.rawQuery(
        'SELECT s.id, s.title, s.author, s.time, s.body, s.status '
        'FROM Song AS s '
        'LEFT JOIN Tag AS t ON s.id = t.idSong '
        'WHERE s.status = 0 AND '
        '(s.title LIKE ? OR s.author LIKE ? OR s.body LIKE ? OR t.tag LIKE ?) '
        'GROUP BY s.id',
        [pattern, pattern, pattern, pattern]);
    return res.map((c) => Song.fromMap(c)).toList();
  }

  Future<List<String>> getSongsTitle(String search) async {
    final List<Song> list = await getSongs(search);
    return list.map((s) => s.title).toList();
  }

  Future<void> newSong(Song song) async {
    final db = await database;
    await db.insert('Song', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSong(Song song) async {
    final db = await database;
    await db.update('Song', song.toMap(),
        where: 'id = ?', whereArgs: [song.id]);
  }

  Future<Song?> getSong(String id) async {
    final db = await database;
    final res = await db.query('Song', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? Song.fromMap(res.first) : null;
  }

  Future<bool> hasSong(String id) async {
    final db = await database;
    final res = await db.query('Song', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  Future<Song?> getSongByTitleAuthor(String title, String? author) async {
    final db = await database;
    final List<Map<String, dynamic>> res;
    if (author != null && author.isNotEmpty) {
      res = await db.query('Song',
          where: 'LOWER(title) = ? AND LOWER(author) = ?',
          whereArgs: [title.toLowerCase(), author.toLowerCase()]);
    } else {
      res = await db.query('Song',
          where: 'LOWER(title) = ?',
          whereArgs: [title.toLowerCase()]);
    }
    return res.isNotEmpty ? Song.fromMap(res.first) : null;
  }

  Future<void> updateOrInsertSong(Song song) async {
    if (await hasSong(song.id)) {
      await updateSong(song);
    } else {
      await newSong(song);
    }
  }

  Future<String?> getLastDate() async {
    final db = await database;
    final res = await db.rawQuery('SELECT MAX(time) AS max FROM Song');
    return res.isNotEmpty ? res.first['max']?.toString() : null;
  }

  // ── Tags ───────────────────────────────────────────────────────────────────

  Future<List<Tag>> getTagsBySongId(String idSong) async {
    final db = await database;
    final res = await db.query('Tag',
        where: "idSong = ? AND tag IS NOT NULL AND tag != ''",
        whereArgs: [idSong]);
    return res.map((c) => Tag.fromMap(c)).toList();
  }

  Future<bool> hasTag(int id) async {
    final db = await database;
    final res = await db.query('Tag', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db
        .update('Tag', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> newTag(Tag tag) async {
    if (await hasTag(tag.id)) {
      await updateTag(tag);
    } else {
      final db = await database;
      await db.insert('Tag', tag.toMap());
    }
  }

  Future<void> deleteTagsBySongId(String idSong) async {
    final db = await database;
    await db.delete('Tag', where: 'idSong = ?', whereArgs: [idSong]);
  }

  // ── Playlists ──────────────────────────────────────────────────────────────

  Future<List<Playlist>> getAllPlaylist() async {
    final db = await database;
    final res = await db.rawQuery(
        'SELECT p.id, p.title, p.time, COUNT(pl.id) AS songCount '
        'FROM Playlist AS p '
        'LEFT JOIN PlaylistSong AS pl ON p.id = pl.idPlaylist '
        'GROUP BY p.id ORDER BY p.title');
    return res.map((c) => Playlist.fromMap(c)).toList();
  }

  Future<int> newPlaylist(String title) async {
    final db = await database;
    return db.rawInsert(
        'INSERT INTO Playlist (title, time) VALUES (?, ?)',
        [title, DateTime.now().millisecondsSinceEpoch]);
  }

  Future<List<Playlist>> hasPlaylist(String title) async {
    final db = await database;
    final res =
        await db.query('Playlist', where: 'title = ?', whereArgs: [title]);
    return res.map((c) => Playlist.fromMap(c)).toList();
  }

  Future<List<Song>> getAllPlaylistSongs(int idPlaylist) async {
    final db = await database;
    final res = await db.rawQuery(
        'SELECT s.id, s.title, s.author, s.time, s.body, s.status '
        'FROM Song AS s '
        'JOIN PlaylistSong AS p ON s.id = p.idSong '
        'WHERE p.idPlaylist = ? AND s.status = 0 '
        'ORDER BY p.id',
        [idPlaylist]);
    return res.map((c) => Song.fromMap(c)).toList();
  }

  Future<void> newSongPlaylist(Playlist pl, Song song) async {
    await newSongPlaylistRaw(pl.id, song.id);
  }

  Future<void> newSongPlaylistRaw(int plID, String songID) async {
    final db = await database;
    await db.rawInsert(
        'INSERT INTO PlaylistSong (idPlaylist, idSong) VALUES (?, ?)',
        [plID, songID]);
  }

  Future<void> removeSongPlaylistRaw(int plID, String songID) async {
    final db = await database;
    await db.rawDelete(
        'DELETE FROM PlaylistSong WHERE idPlaylist = ? AND idSong = ?',
        [plID, songID]);
  }

  Future<void> removePlaylistRaw(int plID) async {
    final db = await database;
    await db.rawDelete('DELETE FROM Playlist WHERE id = ?', [plID]);
    await db.rawDelete(
        'DELETE FROM PlaylistSong WHERE idPlaylist = ?', [plID]);
  }

  Future<void> deleteSong(String id) async {
    final db = await database;
    await db.delete('Tag', where: 'idSong = ?', whereArgs: [id]);
    await db.delete('PlaylistSong', where: 'idSong = ?', whereArgs: [id]);
    await db.delete('Song', where: 'id = ?', whereArgs: [id]);
  }
}
