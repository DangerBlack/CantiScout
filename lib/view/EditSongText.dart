import 'package:flutter/material.dart';
import '../model/Song.dart';
import '../model/Tag.dart';
import '../model/Constants.dart';
import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/Utils.dart';

class EditSongText extends StatefulWidget {
  final Song song;
  final List<bool>? opt;

  const EditSongText({Key? key, required this.song, this.opt}) : super(key: key);

  @override
  EditSongTextState createState() => EditSongTextState();
}

class EditSongTextState extends State<EditSongText> {
  final _bodyController = TextEditingController();
  final _tagInputController = TextEditingController();

  late Song song;

  // Flat list of all current tag strings (scope + custom)
  List<String> _tags = [];

  // Canonical tag value for each scope index (first item in each optTag group)
  static final List<String> _scopeTagValues = Constants.optTag
      .map((group) => group.split(',').first.trim())
      .toList();

  @override
  void initState() {
    super.initState();
    song = widget.song;
    _bodyController.text = song.body;
    _loadTags();
  }

  Future<void> _loadTags() async {
    final List<Tag> existing = await DBProvider.db.getTagsBySongId(song.id);
    final tags = existing.map((t) => t.tag).toList();

    // Merge any scope opts that were checked at creation time
    final opts = widget.opt ?? List.filled(5, false);
    for (int i = 0; i < _scopeTagValues.length; i++) {
      if (opts[i] && !tags.contains(_scopeTagValues[i])) {
        tags.add(_scopeTagValues[i]);
      }
    }

    if (mounted) setState(() => _tags = tags);
  }

  // ── Tag helpers ─────────────────────────────────────────────────────────────

  void _toggleScopeTag(String value) {
    setState(() {
      if (_tags.contains(value)) {
        _tags.remove(value);
      } else {
        _tags.add(value);
      }
    });
  }

  void _addCustomTag(String input) {
    final tag = input.trim().toLowerCase();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
    _tagInputController.clear();
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _saveSong(BuildContext context) async {
    final text = _bodyController.text;
    song.body = text;

    // Parse {author: ...} / {a: ...} from body
    final bodyLower = text.toLowerCase();
    for (final prefix in ['{author:', '{a:']) {
      final idx = bodyLower.indexOf(prefix);
      if (idx != -1) {
        final end = text.indexOf('}', idx);
        if (end != -1) {
          final author = text.substring(idx + prefix.length, end).trim();
          if (author.isNotEmpty) song.author = author;
        }
        break;
      }
    }

    try {
      await DBProvider.db.updateOrInsertSong(song);
      await _saveTags();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(AppLocalizations.of(context).unable_to_save),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> _saveTags() async {
    await DBProvider.db.deleteTagsBySongId(song.id);
    final db = await DBProvider.db.database;
    for (final tag in _tags) {
      await db.insert('Tag', {'idSong': song.id, 'tag': tag});
    }
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).upload_dialog_title),
        content: Text(AppLocalizations.of(context).upload_dialog_body),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).dialog_cancel.toUpperCase()),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context).dialog_confirm.toUpperCase()),
            onPressed: () {
              Navigator.of(ctx).pop();
              _saveSong(context);
            },
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scopeLabels = [
      loc.church,
      loc.lc,
      loc.eg,
      loc.rs,
      loc.other,
    ];

    final customTags = _tags.where((t) => !_scopeTagValues.contains(t)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guida ChordPro',
            onPressed: () => Utils.launchURL('https://www.512b.it/cantiscout/chorpro.html'),
          ),
        ],
      ),
      body: ListView(children: [
        // ── ChordPro body ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: loc.edit_song + song.title,
            ),
            minLines: 20,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            controller: _bodyController,
          ),
        ),

        const Divider(),

        // ── Tags section ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            loc.tags,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        // Scope quick-chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(_scopeTagValues.length, (i) {
              final value = _scopeTagValues[i];
              final label = scopeLabels[i];
              return FilterChip(
                label: Text(label),
                selected: _tags.contains(value),
                onSelected: (_) => _toggleScopeTag(value),
              );
            }),
          ),
        ),

        // Custom tags row
        if (customTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: customTags
                  .map((t) => Chip(
                        label: Text('#$t'),
                        onDeleted: () => _removeTag(t),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ),

        // Custom tag input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInputController,
                  decoration: const InputDecoration(
                    labelText: 'Aggiungi tag personalizzato',
                    prefixText: '#',
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _addCustomTag,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Aggiungi',
                onPressed: () => _addCustomTag(_tagInputController.text),
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showConfirmDialog(context),
        tooltip: loc.save,
        child: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }
}
