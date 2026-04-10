import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../model/Song.dart';

class Utils {
  /// Parse a ChordPro-formatted string into a Song.
  /// Extracts {title:}, {t:}, {author:}, {a:} directives.
  static Song parseSongFromChordPro(String text) {
    String title = '';
    String? author;

    final titleMatch =
        RegExp(r'\{(?:title|t)\s*:\s*(.+?)\}', caseSensitive: false)
            .firstMatch(text);
    if (titleMatch != null) title = titleMatch.group(1)!.trim();

    final authorMatch =
        RegExp(r'\{(?:author|a)\s*:\s*(.+?)\}', caseSensitive: false)
            .firstMatch(text);
    if (authorMatch != null) author = authorMatch.group(1)!.trim();

    // Fallback title: first non-empty, non-directive line
    if (title.isEmpty) {
      title = text
          .split('\n')
          .map((l) => l.trim())
          .firstWhere(
              (l) => l.isNotEmpty && !l.startsWith('{') && !l.startsWith('#'),
              orElse: () => 'Canzone senza titolo');
    }

    return Song.create(title: title, author: author, body: text.trim());
  }

  static Future<void> updatePreferences(String key, dynamic value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is Color) {
      await prefs.setInt(key, value.value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  static Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
