import 'package:flutter/material.dart';



class Constants {
  static final String urlPathSong = "https://www.512b.it/cantiscout/php/song.php";
  static final String urlPathSongList = "https://www.512b.it/cantiscout/php/get.php?max=";
  static final String tokenApi = 'https://www.512b.it/cantiscout/api/';

  static final String token = 'token';
  static final String tokenMewSong = 'updateSong';
  static final String tokenPlaylist = 'playlist/';


  static final String gravatarUrl = "https://www.gravatar.com/avatar/";

  static final String sharedDefaultFontSize = "defaultFontSize";
  static final String sharedAutoscroll = "Autoscroll";
  static final String sharedFontStyle = "FontStyle";
  static final String sharedFontColor = "FontColor";

  static final double initialFontSize = 18.0;
  static final bool initialAutoscroll = false;
  static final String initialFontStyle = "Roboto";
  static final int initialColor = Colors.black.value;


  //USER space

  static final String sharedMail = "mail";
  static final String sharedName = "name";
  static final String sharedToken = "token";

  static final String defaultMail = "unkown";
  static final String defaultName = "Unkown";

}