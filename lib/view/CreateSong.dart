import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../view/EditSongText.dart';
import '../controller/AppLocalizations.dart';

class CreateSongStatefull extends StatefulWidget {
  const CreateSongStatefull({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  CreateSong createState() => CreateSong();
}

class CreateSong extends State<CreateSongStatefull> {
  final myController = TextEditingController();
  bool _validate = false;

  final List<bool> _opt = <bool>[false, false, false, false, false];

  void _routeToEditor(BuildContext context, String title) {
    final song = Song.create(
      title: title,
      body: '{title: $title}\n\n',
    );
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditSongText(song: song, opt: _opt)),
    );
  }

  void _create(BuildContext context) {
    final text = myController.text;
    if (text.isNotEmpty) {
      _routeToEditor(context, text);
      _validate = false;
    } else {
      setState(() => _validate = true);
    }
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(children: [
          const Hero(
            tag: 'hero',
            child: Padding(
              padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 48.0,
                child: Icon(Icons.album),
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).chose_title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: TextField(
              textAlign: TextAlign.center,
              controller: myController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).text_title,
                errorText: _validate
                    ? AppLocalizations.of(context).value_must_not_be_empty
                    : null,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).choose_scope,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: 40.0, bottom: 40.0, left: 40.0, right: 40.0),
            child: Row(children: [
              _optColumn(context, AppLocalizations.of(context).church, 0),
              _optColumn(context, AppLocalizations.of(context).lc, 1),
              _optColumn(context, AppLocalizations.of(context).eg, 2),
              _optColumn(context, AppLocalizations.of(context).rs, 3),
              _optColumn(context, AppLocalizations.of(context).other, 4),
            ]),
          ),
          Row(children: [
            Expanded(
              child: TextButton(
                child: Text(
                  AppLocalizations.of(context).undo,
                  style: const TextStyle(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: TextButton(
                child: Text(
                  AppLocalizations.of(context).create,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => _create(context),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _optColumn(BuildContext context, String label, int index) {
    return Expanded(
      child: Column(
        children: [
          Text(label),
          Checkbox(
            value: _opt[index],
            onChanged: (value) =>
                setState(() => _opt[index] = value ?? false),
          ),
        ],
      ),
    );
  }
}
