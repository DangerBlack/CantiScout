import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/ChopackController.dart';
import '../model/Chartset.dart';
import '../model/Constants.dart';
import '../model/Song.dart';
import '../view/BleReceiveView.dart';
import '../view/BleSendView.dart';

enum _BulkConflictPolicy { skip, keepBoth, replace }

class SettingsStateful extends StatefulWidget {
  const SettingsStateful({Key? key, this.title, this.onImportComplete})
      : super(key: key);
  final String? title;
  final VoidCallback? onImportComplete;

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
    _fontSizeController =
        TextEditingController(text: Constants.initialFontSize.toString());
    _usernameController = TextEditingController();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(Constants.sharedDefaultFontSize) ??
        Constants.initialFontSize;
    final username = prefs.getString(Constants.sharedUsername) ?? '';

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
      _username = username;
      _usernameController.text = username;
    });
  }

  Future<void> _updatePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    else if (value is double) await prefs.setDouble(key, value);
    else if (value is int) await prefs.setInt(key, value);
    else if (value is String) await prefs.setString(key, value);
  }

  // ── Loading dialog ──────────────────────────────────────────────────────────

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Libreria: import .chopack ───────────────────────────────────────────────

  Future<void> _importChopack() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      if (!path.toLowerCase().endsWith('.chopack')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un file .chopack')),
        );
        return;
      }

      if (!mounted) return;
      _showLoadingDialog('Lettura del file in corso…');

      final (incoming, tagsMap) = await ChopackController.importPack(path);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

      if (incoming.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessuna canzone trovata nel file.')),
        );
        return;
      }

      final newSongs = <Song>[];
      final conflicts = <Song>[];
      for (final song in incoming) {
        final existing =
            await DBProvider.db.getSongByTitleAuthor(song.title, song.author);
        (existing != null ? conflicts : newSongs).add(song);
      }

      _BulkConflictPolicy policy = _BulkConflictPolicy.skip;
      if (conflicts.isNotEmpty && mounted) {
        final chosen = await showDialog<_BulkConflictPolicy>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Canzoni già presenti'),
            content: Text(
                '${newSongs.length} nuove, ${conflicts.length} già presenti.\n'
                'Cosa fare con i duplicati?'),
            actions: [
              TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _BulkConflictPolicy.skip),
                  child: const Text('SALTA')),
              TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _BulkConflictPolicy.keepBoth),
                  child: const Text('MANTIENI ENTRAMBE')),
              TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _BulkConflictPolicy.replace),
                  child: const Text('SOSTITUISCI')),
            ],
          ),
        );
        if (chosen != null) policy = chosen;
      }

      if (!mounted) return;
      _showLoadingDialog('Importazione in corso…');

      int imported = 0;
      for (final song in newSongs) {
        final saved =
            Song.create(title: song.title, author: song.author, body: song.body);
        await DBProvider.db.newSong(saved);
        if (tagsMap.containsKey(song.id)) {
          await ChopackController.saveTags(saved.id, tagsMap[song.id]!);
        }
        imported++;
      }

      for (final song in conflicts) {
        switch (policy) {
          case _BulkConflictPolicy.skip:
            break;
          case _BulkConflictPolicy.keepBoth:
            final saved = Song.create(
                title: '${song.title} (2)',
                author: song.author,
                body: song.body);
            await DBProvider.db.newSong(saved);
            if (tagsMap.containsKey(song.id)) {
              await ChopackController.saveTags(saved.id, tagsMap[song.id]!);
            }
            imported++;
          case _BulkConflictPolicy.replace:
            final existing = await DBProvider.db
                .getSongByTitleAuthor(song.title, song.author);
            if (existing != null) {
              existing.body = song.body;
              existing.author = song.author;
              await DBProvider.db.updateSong(existing);
              if (tagsMap.containsKey(song.id)) {
                await ChopackController.saveTags(
                    existing.id, tagsMap[song.id]!);
              }
              imported++;
            }
        }
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

      widget.onImportComplete?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported canzoni importate!')),
      );
    } catch (e) {
      // Close any open loading dialog before showing the error.
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore importazione: $e')),
        );
      }
    }
  }

  // ── Libreria: export .chopack ───────────────────────────────────────────────

  Future<void> _exportChopack() async {
    try {
      final songs = await DBProvider.db.getAllSongs();
      if (!mounted) return;
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessuna canzone da esportare.')),
        );
        return;
      }
      await ChopackController.exportPack(songs, 'CantScout - Libreria');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore esportazione: $e')),
      );
    }
  }

  // ── App settings helpers ────────────────────────────────────────────────────

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
              child: Text(f as String, style: TextStyle(fontFamily: f as String)),
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
        // ── Libreria ──────────────────────────────────────────────────────────
        ListTile(
          title: Text('LIBRERIA', style: _titleFontStyle),
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Importa raccolta (.chopack)'),
          onTap: _importChopack,
        ),
        ListTile(
          leading: const Icon(Icons.archive),
          title: const Text('Esporta libreria (.chopack)'),
          onTap: _exportChopack,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.bluetooth),
          title: const Text('Invia via Bluetooth'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BleSendView()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bluetooth_searching),
          title: const Text('Ricevi via Bluetooth'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BleReceiveView()),
          ).then((_) => widget.onImportComplete?.call()),
        ),
        const Divider(),

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
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                _username = value.trim();
                _updatePref(Constants.sharedUsername, value.trim());
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() => _username = value.trim());
                _updatePref(Constants.sharedUsername, value.trim());
              }
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
