import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_colorpicker/block_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Constants.dart';

class SettingsStateful extends StatefulWidget {
  SettingsStateful({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Settings createState() => Settings();
}

class Settings extends State {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _titleFontStyle =
      const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold);
  List<Widget> settings = new List<Widget>();

  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);
  ValueChanged<Color> onColorChanged;

  bool _validate = false;
  bool _autoscroll = false;
  String dropdownValue = 'Roboto';

  TextEditingController _controller;

  Settings() : super() {
    _controller = new TextEditingController(text: Constants.initialFontSize.toString());
    _controller.addListener(() {
      if (_controller.text.isNotEmpty) {
        try {
          updatePreferences(
              Constants.sharedDefaultFontSize, double.parse(_controller.text));
        } on FormatException {}
      }
    });
    setPreferences();
  }

  setPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double fontSize = (prefs.getDouble(Constants.sharedDefaultFontSize) ??
        Constants.initialFontSize);
    setState(() {
      _controller.text = fontSize.toString();

      _autoscroll = (prefs.getBool(Constants.sharedAutoscroll) ??
          Constants.initialAutoscroll);

      pickerColor = Color((prefs.getInt(Constants.sharedFontColor) ??
          Constants.initialColor));
    });

  }

  updatePreferences(String key, var value) async {
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
  }

  changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  showColorPicker() {
    showDialog(
      context: context,
      child: AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: changeColor,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Got it'),
            onPressed: () {
              setState(() => currentColor = pickerColor);
              updatePreferences(Constants.sharedFontColor,currentColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    settings = new List<Widget>();
    settings.add(
      new ListTile(
        title: new Text(
          "Impostazioni del testo".toUpperCase(),
          textAlign: TextAlign.left,
          style: _titleFontStyle,
        ),
      ),
    );
    settings.add(
      new ListTile(
        title: TextField(
          textAlign: TextAlign.center,
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Dimensione del testo',
            errorText: _validate ? 'Value Can\'t Be Empty' : null,
          ),
        ),
      ),
    );

    settings.add(
      new ListTile(
        title: new Text(
          "Font",
          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
        ),
        subtitle: DropdownButton<String>(
          hint: Text("Choose Font"),
          value: dropdownValue,
          onChanged: (String newValue) {
            setState(() {
              dropdownValue = newValue;
            });
          },
          items: <String>['Roboto', 'Monotipe', 'Arial', 'Times']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );

    settings.add(
      new ListTile(
        leading: Icon(
          Icons.color_lens,
          color: pickerColor,
        ),
        title: Text("Colore accordi"),
        subtitle: Text("Premere per modificare"),
        onTap: () {
          showColorPicker();
        },
      ),
    );

    settings.add(
      new ListTile(
        title: new Text(
          "Impostazioni dell'applicazione".toUpperCase(),
          textAlign: TextAlign.left,
          style: _titleFontStyle,
        ),
      ),
    );

    settings.add(SwitchListTile(
      title: const Text('Autoscroll'),
      value: _autoscroll,
      onChanged: (bool value) {
        updatePreferences(Constants.sharedAutoscroll, value);
        setState(() {
          _autoscroll = value;
        });
      },
      secondary: const Icon(Icons.text_rotation_none),
    ));

    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: new Column(
        mainAxisSize: MainAxisSize.min,
        children: settings,
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    _controller.dispose();
    super.dispose();
  }
}
