import 'package:flutter/material.dart';

class Choice {
  Choice({required this.title, required this.icon, this.action});

  String title;
  IconData icon;
  Function? action;
}
