import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawerItem {
  String title;
  IconData icon;
  Function action;

  DrawerItem(this.title, this.icon, this.action);
}