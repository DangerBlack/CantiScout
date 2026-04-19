import 'package:flutter/material.dart';

class Constants {
  // External URLs
  static const String urlDonation = "https://www.512b.it/cantiscout/donate.html"; // TODO: update when donation page is ready
  static const String urlGuide = "https://dangerblack.github.io/CantiScout/chordpro.html";
  static const String urlTos = "https://dangerblack.github.io/CantiScout/terms.html";
  static const String urlChordPro = "https://dangerblack.github.io/CantiScout/chordpro.html";

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
  static final int initialColor = Colors.black.toARGB32();
  static const double scrollMultiplier = 15.0;
  static const double maxScrollSpeed = 5.0;

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
