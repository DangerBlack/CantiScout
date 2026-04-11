/// Validates ChordPro song bodies and returns a list of formatting issues.
///
/// Checks:
///   - Unknown or misspelled directives (e.g. {autor:} instead of {author:})
///   - Unclosed section blocks (soc/sov/sob without matching eoc/eov/eob)
///   - Stray close tags with no matching open
class ValidationIssue {
  final int line;
  final String message;

  const ValidationIssue({required this.line, required this.message});

  @override
  String toString() => 'Riga $line: $message';
}

class SongValidator {
  // Directives valid in {key: value} context
  static const _knownKVDirectives = {
    'title', 't', 'subtitle', 'st', 'author', 'a',
    'key', 'capo', 'tempo', 'time',
    'comment', 'c', 'comment_italic', 'ci', 'comment_box', 'cb',
  };

  // Directives valid as bare {directive} (no colon)
  static const _knownBareDirectives = {
    'soc', 'start_of_chorus', 'eoc', 'end_of_chorus',
    'sov', 'start_of_verse', 'eov', 'end_of_verse',
    'sob', 'start_of_bridge', 'eob', 'end_of_bridge',
  };

  static const _typos = <String, String>{
    'autor': 'author',
    'autore': 'author',
    'titolo': 'title',
  };

  static const _openDirectives = {
    'soc', 'start_of_chorus',
    'sov', 'start_of_verse',
    'sob', 'start_of_bridge',
  };

  static const _closeDirectives = {
    'eoc', 'end_of_chorus',
    'eov', 'end_of_verse',
    'eob', 'end_of_bridge',
  };

  static final _expKV =
      RegExp(r'\{([a-zA-Z0-9_ ]+)\s*:\s*(.*?)\}');
  static final _expBare =
      RegExp(r'\{\s*([a-zA-Z_]+)([^}:]*)\}');
  static final _expInlineChorus =
      RegExp(r'\{(?:soc|start_of_chorus)\}.*\{(?:eoc|end_of_chorus)\}');

  static List<ValidationIssue> validate(String body) {
    final issues = <ValidationIssue>[];
    final lines = body.split('\n');

    // Stack of open section directives: (name, 1-based line number)
    final openStack = <({String directive, int line})>[];

    for (int i = 0; i < lines.length; i++) {
      final lineNum = i + 1;
      final raw = lines[i];

      // Skip comment lines
      if (raw.trimLeft().startsWith('#')) continue;

      // Inline chorus {soc}...{eoc} on a single line — valid, skip
      if (_expInlineChorus.hasMatch(raw)) continue;

      // Key-value directive: {key: value}
      if (_expKV.hasMatch(raw)) {
        final m = _expKV.firstMatch(raw)!;
        final key = m.group(1)!.trim().toLowerCase();

        if (_typos.containsKey(key)) {
          issues.add(ValidationIssue(
            line: lineNum,
            message:
                'Direttiva "{$key:}" sconosciuta — intendevi "{${_typos[key]}:}"?',
          ));
        } else if (_knownBareDirectives.contains(key) &&
            !_knownKVDirectives.contains(key)) {
          // Section directive mistakenly used with a colon
          issues.add(ValidationIssue(
            line: lineNum,
            message:
                'La direttiva "{$key}" non accetta valore — usa "{$key}" senza i due punti',
          ));
        } else if (!_knownKVDirectives.contains(key) &&
            !_knownBareDirectives.contains(key)) {
          issues.add(ValidationIssue(
            line: lineNum,
            message: 'Direttiva sconosciuta: {$key:}',
          ));
        }
        // KV directives don't open/close sections — no stack tracking needed
        continue;
      }

      // Bare directives: may be multiple on one line
      for (final m in _expBare.allMatches(raw)) {
        final directive = m.group(1)!.toLowerCase().trim();

        if (_typos.containsKey(directive)) {
          issues.add(ValidationIssue(
            line: lineNum,
            message:
                'Direttiva "{$directive}" sconosciuta — intendevi "{${_typos[directive]}}"?',
          ));
          continue;
        }

        if (!_knownBareDirectives.contains(directive) &&
            !_knownKVDirectives.contains(directive)) {
          issues.add(ValidationIssue(
            line: lineNum,
            message: 'Direttiva sconosciuta: {$directive}',
          ));
          continue;
        }

        if (_openDirectives.contains(directive)) {
          openStack.add((directive: directive, line: lineNum));
        } else if (_closeDirectives.contains(directive)) {
          if (openStack.isEmpty) {
            issues.add(ValidationIssue(
              line: lineNum,
              message:
                  'Chiusura "{$directive}" senza apertura corrispondente',
            ));
          } else {
            openStack.removeLast();
          }
        }
      }
    }

    // Report any sections left open
    for (final open in openStack) {
      issues.add(ValidationIssue(
        line: open.line,
        message:
            'Sezione "{${open.directive}}" aperta a riga ${open.line} ma mai chiusa',
      ));
    }

    return issues;
  }
}
