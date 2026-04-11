# CantScout File & Transfer Formats

This document describes the two file formats used by CantScout for storing and
exchanging songs.

---

## 1. ChordPro (`.cho` / `.chopro`)

CantScout stores every song body in a subset of the
[ChordPro](https://www.chordpro.org/) open standard. Files use UTF-8 encoding.

### 1.1 Chords

Chords are written inline with the lyrics, enclosed in square brackets
immediately before the syllable they fall on.

```
[G]Amaz[C]ing grace how [G]sweet the sound
```

The renderer places the chord symbols on a separate line above the lyrics,
aligned to the correct character position using per-font character-width tables.
A monospace font is used so alignment is exact.

### 1.2 Directives

Directives are enclosed in `{ }`. Two forms exist:

- **Key-value**: `{key: value}` — carries a named value.
- **Bare**: `{keyword}` — acts as a block marker.

#### Metadata directives (key-value)

These are shown in the song header, not in the body text.

| Directive | Short form | Description |
|-----------|-----------|-------------|
| `{title: …}` | `{t: …}` | Song title |
| `{author: …}` | `{a: …}` | Author / artist — shown in italics below title |
| `{subtitle: …}` | `{st: …}` | Subtitle — shown in italics below author |
| `{key: …}` | — | Key signature (e.g. `G`, `Am`) — shown as a badge |
| `{capo: …}` | — | Capo position (e.g. `2`) — shown as a badge |
| `{tempo: …}` | — | Tempo in BPM (e.g. `120`) — shown as ♩ = 120 badge |
| `{time: …}` | — | Time signature (e.g. `4/4`) — shown as a badge |

#### Comment directives (key-value)

| Directive | Short form | Description |
|-----------|-----------|-------------|
| `{comment: …}` | `{c: …}` | Grey italic inline comment |
| `{comment_italic: …}` | `{ci: …}` | Same as `{comment:}` |
| `{comment_box: …}` | `{cb: …}` | Comment rendered inside a bordered box |

#### Section directives (bare)

Section directives open and close structural blocks. An optional `label="…"`
attribute overrides the default label shown above the block.

| Open | Close | Default label | Effect |
|------|-------|---------------|--------|
| `{start_of_chorus}` / `{soc}` | `{end_of_chorus}` / `{eoc}` | *(no label)* | Lyrics rendered in italics |
| `{start_of_verse}` / `{sov}` | `{end_of_verse}` / `{eov}` | STROFA | Normal rendering |
| `{start_of_bridge}` / `{sob}` | `{end_of_bridge}` / `{eob}` | BRIDGE | Lyrics rendered in italics |

Example with a custom label:

```
{sov label="Verse 1"}
[G]Lyrics go here
{eov}
```

#### Inline chorus

A chorus that fits on a single line can be written without separate open/close
markers:

```
{soc}[G]Refrain text here{eoc}
```

#### Unknown directives

Any key-value directive whose key is not in the table above is rendered as
**bold** text with the directive's value. This allows ad-hoc annotations without
breaking the file.

### 1.3 Comments

Lines beginning with `#` are ignored by the parser and renderer.

```
# This is a comment — not shown to the user
[G]First verse
```

### 1.4 Metadata extraction on import

When importing a standalone `.chopro` file (without a containing `.chopack`),
CantScout extracts metadata as follows:

1. `{title:}` or `{t:}` → song title
2. `{author:}` or `{a:}` → author
3. Fallback title: first non-empty line that is not a directive or comment

### 1.5 QR code

A single song can be shared as a QR code from the song view. The raw ChordPro
body is encoded. Songs whose body exceeds **2 900 bytes** are flagged as too
large for QR encoding.

### 1.6 Example

```
{title: Amazing Grace}
{author: John Newton}
{key: G}
{tempo: 90}

{sov label="Verse 1"}
[G]Amazing [C]grace how [G]sweet the sound
That [G]saved a [D]wretch like [G]me
{eov}

{soc}
{c: Sing twice}
[C]I once was [G]lost but now am [Em]found
Was [G]blind but [D]now I [G]see
{eoc}
```

---

## 2. CantScout Pack (`.chopack`)

A `.chopack` file is a standard **ZIP archive** that bundles one or more songs
together with their metadata. It is the primary format for library and playlist
export / import.

### 2.1 Archive structure

```
my-pack.chopack
├── metadata.json        ← required; describes all songs and playlists
├── Song Title.chopro    ← one ChordPro file per song
├── Another Song.chopro
└── …
```

File names for `.chopro` entries follow the pattern:

```
{title} - {author}.chopro    (when author is present)
{title}.chopro               (when author is absent)
```

Characters illegal on common filesystems (`< > : " / \ | ? *`) are replaced
with `_`.

### 2.2 `metadata.json` schema (version 2)

```jsonc
{
  "version": 2,
  "exported": "2025-04-10T14:30:00Z",
  "songs": [
    {
      "id":     "550e8400-e29b-41d4-a716-446655440000",
      "title":  "Amazing Grace",
      "author": "John Newton",
      "time":   "2024-01-15T10:00:00.000Z",
      "status": 0,
      "tags":   ["worship", "classic"],
      "file":   "Amazing Grace - John Newton.chopro"
    }
  ],
  "playlists": [
    {
      "title": "Sunday Service",
      "songs": [
        "550e8400-e29b-41d4-a716-446655440000",
        "661f9511-f30c-52e5-b827-557766551111"
      ]
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `version` | integer | Format version (see table below) |
| `exported` | ISO 8601 string | Export timestamp |
| `songs[].id` | UUID v4 | Stable identifier; preserved on re-import |
| `songs[].status` | integer | `0` = active; other values reserved |
| `songs[].tags` | string array | Free-form tag strings |
| `songs[].file` | string | Path of the `.chopro` entry inside this ZIP |
| `playlists[].songs` | UUID array | Ordered list of song IDs |

**Version history:**

| Version | Description |
|---------|-------------|
| 1 | Original format — no `id`, no `tags`, no `playlists` |
| 2 | Current — adds `id`, `tags`, `playlists`; bodies in separate `.chopro` files |

### 2.3 Import behaviour

| Situation | Behaviour |
|-----------|-----------|
| Song not in library | Inserted with original UUID preserved |
| Same title + author already present | User is prompted: skip / keep both / replace |
| "Keep both" chosen | Duplicate saved as `{title} (2)` with a new UUID |
| Playlist title already exists | Incoming songs are appended to the existing playlist |
| Playlist title is new | Playlist is created, then songs are linked |
| Song was skipped at conflict | Not linked to any imported playlist |

### 2.4 Fallback import (no `metadata.json`)

If `metadata.json` is absent, CantScout scans the archive for any `.chopro`
or `.cho` file and imports each one using the ChordPro metadata-extraction
rules described in §1.4. Tags and playlists are not restored in this path.

### 2.5 Generating a `.chopack` from raw data

The `raw/` directory in this repository contains a Python script that converts
a PHPMyAdmin JSON export into a `.chopack`:

```bash
cd raw/
python3 convert_db.py
```

Output: `raw/canti_scout_import.chopack`

To apply known data-quality fixes before converting:

```bash
cd raw/
python3 fix_songs.py   # patches JSON then calls convert_db.py automatically
```
