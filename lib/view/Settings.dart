import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/block_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_xlider/flutter_xlider.dart';
//import '../view/xsliderfixed.dart';
import '../model/Chartset.dart';

import '../model/Constants.dart';

import '../controller/AppLocalizations.dart';

class SettingsStateful extends StatefulWidget {
  SettingsStateful({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Settings createState() => Settings();
}

class Settings extends State {
  final _titleFontStyle =
      const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold);
  List<Widget> settings = new List<Widget>();

  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);
  ValueChanged<Color> onColorChanged;

  bool _validate = false;
  bool _autoscroll = false;
  String dropdownValue = 'Roboto';
  double _speed;

  TextEditingController _controller;

  FlutterSlider gg;

  Settings() : super() {
    _controller =
        new TextEditingController(text: Constants.initialFontSize.toString());
    _controller.addListener(() {
      if (_controller.text.isNotEmpty) {
        try {
          updatePreferences(
              Constants.sharedDefaultFontSize, double.parse(_controller.text));
        } on FormatException {}
      }
    });
  }

  setPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double fontSize = (prefs.getDouble(Constants.sharedDefaultFontSize) ??
        Constants.initialFontSize);
    setState(() {
      _speed = (prefs.getDouble(Constants.sharedAutoscrollSpeed) ??
          Constants.initialAutoscrollSpeed);

      _controller.text = fontSize.toString();

      _autoscroll = (prefs.getBool(Constants.sharedAutoscroll) ??
          Constants.initialAutoscroll);

      pickerColor = Color(
          (prefs.getInt(Constants.sharedFontColor) ?? Constants.initialColor));

      dropdownValue = (prefs.getString(Constants.sharedFontStyle) ??
          Constants.initialFontStyle);

      print("Speed: " + _speed.toString());
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
    if (value is String) {
      await prefs.setString(key, value);
    }
  }

  changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context).pick_a_color),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: currentColor,
                onColorChanged: changeColor,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(AppLocalizations.of(context).done),
                onPressed: () {
                  setState(() => currentColor = pickerColor);
                  updatePreferences(Constants.sharedFontColor, currentColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  _buildFontList() {
    List<DropdownMenuItem<String>> l = new List<DropdownMenuItem<String>>();
    List f = Charset.getFonts();
    print(f);
    f.forEach((value) => {
          l.add(DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: new TextStyle(fontFamily: value)),
          ))
        });
    return l;
  }

  @override
  void initState() {
    super.initState();
    setPreferences();
  }

  @override
  Widget build(BuildContext context) {
    settings = new List<Widget>();
    settings.add(
      new ListTile(
        title: new Text(
          AppLocalizations.of(context).text_settings.toUpperCase(),
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
            labelText: AppLocalizations.of(context).text_size,
            errorText: _validate ? AppLocalizations.of(context).value_must_not_be_empty : null,
          ),
        ),
      ),
    );

    settings.add(
      new ListTile(
        title: new Text(
          AppLocalizations.of(context).font,
          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
        ),
        subtitle: DropdownButton<String>(
            hint: Text(AppLocalizations.of(context).choose_font),
            value: dropdownValue,
            isExpanded: true,
            onChanged: (String newValue) {
              setState(() {
                dropdownValue = newValue;
                updatePreferences(Constants.sharedFontStyle, newValue);
              });
            },
            items: _buildFontList()),
      ),
    );

    settings.add(
      new ListTile(
        leading: Icon(
          Icons.color_lens, //fiber_manual_record
          color: pickerColor,
        ),
        title: Text(AppLocalizations.of(context).chord_color),
        subtitle: Text(AppLocalizations.of(context).chord_color_press),
        onTap: () {
          showColorPicker();
        },
      ),
    );

    settings.add(
      new ListTile(
        title: new Text(
          AppLocalizations.of(context).app_settings.toUpperCase(),
          textAlign: TextAlign.left,
          style: _titleFontStyle,
        ),
      ),
    );

    settings.add(SwitchListTile(
      title: Text(AppLocalizations.of(context).auto_scroll),
      value: _autoscroll,
      onChanged: (bool value) {
        updatePreferences(Constants.sharedAutoscroll, value);
        setState(() {
          _autoscroll = value;
        });
      },
      secondary: Icon(Constants.autoscrollIcon), //text_rotation_none
    ));

    print("Velocita: " + _speed.toString());

    /*settings.add(
      new ListTile(
        title: new Text(
          "Velocità autoscroll",
          textAlign: TextAlign.left,
          style: _titleFontStyle,
        ),
      ),
    );*/

    /*
    settings.add(
      Slider(
        min: 0.0,
        divisions: Constants.maxScrollSpeed.toInt(),
        max: Constants.maxScrollSpeed,
        onChanged: (newRating) {
          setState((){
            _speed = newRating;
            updatePreferences(Constants.sharedAutoscrollSpeed, _speed);
          });
        },
        value: _speed,
      ),
    );*/

    if (_speed != null) {
      gg = new FlutterSlider(
        trackBar: FlutterSliderTrackBar(
          activeTrackBarColor: Theme.of(context).primaryColorLight,
          activeTrackBarHeight: 5,
          inactiveTrackBarColor: Colors.grey.shade200,
        ),
        values: <double>[_speed],
        min: 0,
        max: Constants.maxScrollSpeed,
        handler: FlutterSliderHandler(
          child: Material(
            type: MaterialType.circle,
            color: Theme.of(context).primaryColor,
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Constants.autoscrollIcon,
                //Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        onDragging: (handlerIndex, lowerValue, upperValue) {
          setState(() {
            print("Setto autoscroll " + lowerValue.toString());
            if (lowerValue < 0.0) {
              lowerValue = 0.0;
            }
            _speed = lowerValue;
            updatePreferences(Constants.sharedAutoscrollSpeed, lowerValue);
          });
        },
      );
      settings.add(Padding(
        padding: EdgeInsets.all(10),
        child: gg,
      ));
    }

    //updateList();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: new ListView(
        //mainAxisSize: MainAxisSize.min,
        //mainAxisAlignment: MainAxisAlignment.start,
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
