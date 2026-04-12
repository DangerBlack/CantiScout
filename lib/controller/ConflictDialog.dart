import 'package:flutter/material.dart';
import '../model/Song.dart';

/// What to do when an imported song already exists in the library.
enum ConflictPolicy { skip, keepBoth, replace }

/// Dialog for a single-song import conflict (e.g. importing a .chopro file).
///
/// Returns [ConflictPolicy.keepBoth] or [ConflictPolicy.replace],
/// or null if the user cancelled.
Future<ConflictPolicy?> showSingleConflictDialog(
  BuildContext context,
  Song song,
) {
  final title = song.title;
  final author = song.author;
  return showDialog<ConflictPolicy>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Canzone già esistente'),
      content: Text(
        '"$title"${author != null ? ' di $author' : ''}'
        ' è già presente. Cosa vuoi fare?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('ANNULLA'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ConflictPolicy.keepBoth),
          child: const Text('MANTIENI ENTRAMBE'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ConflictPolicy.replace),
          child: const Text('SOSTITUISCI'),
        ),
      ],
    ),
  );
}

/// Dialog for a bulk import conflict (e.g. importing a .chopack or via BLE).
///
/// [conflictCount] is the number of songs that already exist.
/// [newCount] is the number of songs that are genuinely new (optional — shown
/// when > 0, e.g. in .chopack imports where both counts are known).
///
/// Returns the chosen [ConflictPolicy], or null if the user dismissed the dialog.
Future<ConflictPolicy?> showBulkConflictDialog(
  BuildContext context, {
  required int conflictCount,
  int newCount = 0,
}) {
  final String content = newCount > 0
      ? '$newCount nuove, $conflictCount già presenti.\nCosa fare con i duplicati?'
      : '$conflictCount '
        '${conflictCount == 1 ? 'canzone è già presente' : 'canzoni sono già presenti'}'
        ' nella libreria.';

  return showDialog<ConflictPolicy>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Canzoni già presenti'),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, ConflictPolicy.skip),
          child: const Text('SALTA'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ConflictPolicy.keepBoth),
          child: const Text('MANTIENI ENTRAMBE'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ConflictPolicy.replace),
          child: const Text('SOSTITUISCI'),
        ),
      ],
    ),
  );
}
