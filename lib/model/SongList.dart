import "Song.dart";

class SongList{
  List<Song> list = new List<Song>();

  SongList(){
  }

  Song get(int i){
    return list[i];
  }
}