import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Chartset.dart';
import '../model/Constants.dart';
import '../controller/AppLocalizations.dart';

class SettingsStateful extends StatefulWidget {
  const SettingsStateful({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  Settings createState() => Settings();
}

class Settings extends State<SettingsStateful> {
  final _titleFontStyle =
      const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold);

  Color pickerColor = Colors.black;
  Color currentColor = Colors.black;

  bool _autoscroll = false;
  String dropdownValue = 'Roboto';
  double _speed = Constants.initialAutoscrollSpeed;
  double _fontSize = Constants.initialFontSize;
  String _username = '';

  late TextEditingController _fontSizeController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _fontSizeController = TextEditingController(
        text: Constants.initialFontSize.toString());
    _usernameController = TextEditingController();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize =
        prefs.getDouble(Constants.sharedDefaultFontSize) ?? Constants.initialFontSize;
    final username =
        prefs.getString(Constants.sharedUsername) ?? '';

    // Generate random scout username on first run
    final resolvedUsername = username.isEmpty ? _generateUsername(prefs) : username;

    setState(() {
      _fontSize = fontSize;
      _speed = prefs.getDouble(Constants.sharedAutoscrollSpeed) ??
          Constants.initialAutoscrollSpeed;
      _fontSizeController.text = fontSize.toString();
      _autoscroll =
          prefs.getBool(Constants.sharedAutoscroll) ?? Constants.initialAutoscroll;
      pickerColor = Color(
          prefs.getInt(Constants.sharedFontColor) ?? Constants.initialColor);
      currentColor = pickerColor;
      dropdownValue = prefs.getString(Constants.sharedFontStyle) ??
          Constants.initialFontStyle;
      _username = resolvedUsername;
      _usernameController.text = resolvedUsername;
    });
  }

  String _generateUsername(SharedPreferences prefs) {
    const adjectives = [
      'Veloce', 'Forte', 'Saggio', 'Coraggioso', 'Agile',
      'Fedele', 'Furbo', 'Vivace', 'Ardito', 'Pronto',
    ];
    const animals = [
      'Lupo', 'Volpe', 'Aquila', 'Orso', 'Cervo',
      'Falco', 'Lontra', 'Castoro', 'Lince', 'Gufo',
    ];
    final rng = Random();
    final name = adjectives[rng.nextInt(adjectives.length)] +
        animals[rng.nextInt(animals.length)];
    prefs.setString(Constants.sharedUsername, name);
    return name;
  }

  Future<void> _updatePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    else if (value is double) await prefs.setDouble(key, value);
    else if (value is int) await prefs.setInt(key, value);
    else if (value is String) await prefs.setString(key, value);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).pick_a_color),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (c) => setState(() => pickerColor = c),
          ),
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).done),
            onPressed: () {
              setState(() => currentColor = pickerColor);
              _updatePref(Constants.sharedFontColor, currentColor.value);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildFontList() {
    return Charset.getFonts()
        .map((f) => DropdownMenuItem<String>(
              value: f as String,
              child: Text(f as String,
                  style: TextStyle(fontFamily: f as String)),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: ListView(children: [
        // ── Identity ──────────────────────────────────────────────────────────
        ListTile(
          title: Text(
            AppLocalizations.of(context).app_settings.toUpperCase(),
            style: _titleFontStyle,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).username,
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() => _username = value.trim());
                _updatePref(Constants.sharedUsername, value.trim());
              }
            },
          ),
          trailing: IconButton(
            icon: const Icon(Icons.casino),
            tooltip: AppLocalizations.of(context).random_username,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final name = _generateUsername(prefs);
              setState(() {
                _username = name;
                _usernameController.text = name;
              });
            },
          ),
        ),

        // ── Text settings ─────────────────────────────────────────────────────
        ListTile(
          title: Text(
            AppLocalizations.of(context).text_settings.toUpperCase(),
            style: _titleFontStyle,
          ),
        ),
        ListTile(
          title: TextField(
            textAlign: TextAlign.center,
            controller: _fontSizeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).text_size,
            ),
            onChanged: (value) {
              final d = double.tryParse(value);
              if (d != null) {
                setState(() => _fontSize = d);
                _updatePref(Constants.sharedDefaultFontSize, d);
              }
            },
          ),
        ),
        ListTile(
          title: Text(
            AppLocalizations.of(context).font,
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
          subtitle: DropdownButton<String>(
            value: dropdownValue,
            isExpanded: true,
            onChanged: (String? newValue) {
              if (newValue == null) return;
              setState(() => dropdownValue = newValue);
              _updatePref(Constants.sharedFontStyle, newValue);
            },
            items: _buildFontList(),
          ),
        ),
        ListTile(
          leading: Icon(Icons.color_lens, color: pickerColor),
          title: Text(AppLocalizations.of(context).chord_color),
          subtitle: Text(AppLocalizations.of(context).chord_color_press),
          onTap: _showColorPicker,
        ),

        // ── Autoscroll ────────────────────────────────────────────────────────
        SwitchListTile(
          title: Text(AppLocalizations.of(context).auto_scroll),
          value: _autoscroll,
          onChanged: (bool value) {
            _updatePref(Constants.sharedAutoscroll, value);
            setState(() => _autoscroll = value);
          },
          secondary: const Icon(Constants.autoscrollIcon),
        ),
        if (_autoscroll)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Slider(
              value: _speed,
              min: 0,
              max: Constants.maxScrollSpeed,
              divisions: Constants.maxScrollSpeed.toInt(),
              label: _speed.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _speed = value);
                _updatePref(Constants.sharedAutoscrollSpeed, value);
              },
            ),
          ),
      ]),
    );
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
