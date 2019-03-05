import 'package:flutter/material.dart';
import '../model/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double fontSize = (prefs.getDouble(key) ?? Constants.initialFontSize);
  }

}