import 'package:flutter/material.dart';

class Constants {
  // External URLs
  static const String urlDonation = "https://www.512b.it/cantiscout/donate.html";
  static const String urlGuide = "https://www.512b.it/cantiscout/guide.html";
  static const String urlTos = "https://www.512b.it/cantiscout/tos.html";
  static const String urlChordPro = "https://www.512b.it/cantiscout/chordpro.html";

  // Display settings keys
  static const String sharedDefaultFontSize = "defaultFontSize";
  static const String sharedAutoscroll = "Autoscroll";
  static const String sharedAutoscrollSpeed = "AutoscrollSpeed";
  static const String sharedFontStyle = "FontStyle";
  static const String sharedFontColor = "FontColor";

  // User identity
  static const String sharedUsername = "username";
  static const String defaultUsername = "Scout";

  // Display defaults
  static const double initialFontSize = 18.0;
  static const bool initialAutoscroll = false;
  static const double initialAutoscrollSpeed = 3.0;
  static const String initialFontStyle = "Roboto";
  static final int initialColor = Colors.black.value;
  static const double scrollMultiplier = 25.0;
  static const double maxScrollSpeed = 10.0;

  static const IconData autoscrollIcon = Icons.playlist_play;
  static const IconData autoscrollIconPause = Icons.pause;

  static const List<String> optTag = <String>[
    "chiesa,messa,liturgia,preghiera",
    "lc,lupetti,coccinelle,branco,cerchio",
    "eg,esploratori,guide,reparto",
    "rs,rover,scolte,clan",
    "altro",
  ];
}
