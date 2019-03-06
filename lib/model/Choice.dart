import 'package:flutter/material.dart';
class Choice {
  Choice({this.title, this.icon, this.action});

  String title;
  IconData icon;
  Function action;
}