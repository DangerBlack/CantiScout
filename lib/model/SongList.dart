import "Song.dart";

class SongList{
  List<Song> list = new List<Song>();

  Song get(int i){
    return list[i];
  }
}