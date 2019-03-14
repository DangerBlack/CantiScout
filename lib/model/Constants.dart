import 'package:flutter/material.dart';



class Constants {
  static final String urlPathSong = "https://www.512b.it/cantiscout/php/song.php";
  static final String urlPathSongList = "https://www.512b.it/cantiscout/php/get.php?max=";
  static final String tokenApi = 'https://www.512b.it/cantiscout/api/';

  static final String token = 'token';
  static final String register = 'register';
  static final String updatePassword = 'updatePassword';
  static final String report = 'report';
  static final String tokenExpire = 'token/expire';
  static final String tokenUpdateSong = 'updateSong';
  static final String tokenNewSong = 'insertSong';
  static final String tokenPlaylist = 'playlist/';

  static final String  lastDateCheck = 'lastDateCheck';
  static final Duration  waitBetweenCheck = new Duration(days:1);


  static final String gravatarUrl = "https://www.gravatar.com/avatar/";

  static final String sharedDefaultFontSize = "defaultFontSize";
  static final String sharedAutoscroll = "Autoscroll";
  static final String sharedAutoscrollSpeed = "AutoscrollSpeed";
  static final String sharedFontStyle = "FontStyle";
  static final String sharedFontColor = "FontColor";

  static final double initialFontSize = 18.0;
  static final bool initialAutoscroll = false;
  static final double initialAutoscrollSpeed = 3.0;
  static final String initialFontStyle = "Roboto";
  static final int initialColor = Colors.black.value;
  static final double scrollMultiplier = 5.0;
  static final double maxScrollSpeed = 10.0;

  static final IconData autoscrollIcon = Icons.playlist_play;
  static final IconData autoscrollIconPause = Icons.pause;

  //USER space

  static final String sharedMail = "mail";
  static final String sharedName = "name";
  static final String sharedToken = "token";

  static final String defaultMail = "unkown";
  static final String defaultName = "Unkown";


  static final List<String> reportOption = <String>[
    "copiright",
    "contenuti espliciti o offensivi",
    "note errate",
    "testo errato",
    "altro"
  ];


  static final List<String> optTag = <String>[
    "chiesa,messa,liturgia,preghiera",
    "lc,lupetti,coccinelle,branco,cerchio",
    "eg,esploratori,guide,reparto",
    "rs,rover,scolte,clan",
    "altro"
  ];

}