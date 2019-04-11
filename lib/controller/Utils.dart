import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:url_launcher/url_launcher.dart';



class Utils {
  static updatePreferences(String key, var value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    }
    if (value is double) {
      await prefs.setDouble(key, value);
    }
    if (value is Color) {
      await prefs.setInt(key, value.value);
    }
    if (value is String) {
      await prefs.setString(key, value);
    }
  }

  getPreferences(key, _callBack) async {
  }

  static generateMd5(String data) {
    var content = new Utf8Encoder().convert(data);
    var md5 = crypto.md5;
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}