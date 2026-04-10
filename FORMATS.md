# CantScout File & Transfer Formats

This document describes the two file formats used by CantScout and the BLE
wire protocol used for device-to-device transfers.

---

## 1. ChordPro (`.cho` / `.chopro`)

CantScout uses a subset of the [ChordPro](https://www.chordpro.org/) standard
for individual song files. The body of every song in the database is stored in
this format.

### 1.1 Chords

Chords are written inline with the lyrics, enclosed in square brackets
immediately before the syllable they apply to.

```
[G]Amaz[C]ing grace how [G]sweet the sound
```

The renderer places chords on a separate line above the lyrics, aligned to the
correct character position using per-font character-width tables.

### 1.2 Directives

Directives are enclosed in `{ }` and control metadata or song structure.

| Directive | Short form | Description |
|---|---|---|
| `{title: …}` | `{t: …}` | Song title |
| `{author: …}` | `{a: …}` | Author / artist — rendered in *italics* |
| `{start_of_chorus}` | `{soc}` | Begin chorus block — text rendered in *italics* |
| `{end_of_chorus}` | `{eoc}` | End chorus block |

Any other `{key: value}` directive is rendered as **bold** text.

Directives without a colon (e.g. bare `{soc}`) are treated as block markers.
An inline chorus (`{soc}lyrics{eoc}` on a single line) is also supported.

### 1.3 Comments

Lines starting with `#` are ignored by the parser and renderer.

### 1.4 Metadata extraction

When importing a `.chopro` file without a containing `.chopack`, CantScout
extracts metadata as follows:

1. `{title:}` or `{t:}` → song title
2. `{author:}` or `{a:}` → author
3. Fallback title: first non-empty line that is not a directive or comment

### 1.5 Example

```
{title: Amazing Grace}
{author: John Newton}

[G]Amazing [C]grace how [G]sweet the sound
That [G]saved a [D]wretch like [G]me

{soc}
[C]I once was [G]lost but now am [Em]found
Was [G]blind but [D]now I [G]see
{eoc}
```

### 1.6 QR code

A single song can be shared as a QR code directly from the song view. Songs
whose body exceeds **2 900 bytes** are flagged as too large for QR encoding.

---

## 2. CantScout Pack (`.chopack`)

A `.chopack` is a standard **ZIP archive** that bundles one or more songs with
their metadata. It is the primary format for library and playlist export/import.

### 2.1 Archive structure

```
my-pack.chopack          ← ZIP archive
├── metadata.json        ← required: all metadata (version 2)
├── Song Title.chopro    ← one ChordPro file per song
├── Another Song.chopro
└── …
```

File names for `.chopro` entries follow the pattern:

```
{title} - {author}.chopro   (when author is present)
{title}.chopro              (when author is absent)
```

Characters illegal on common filesystems (`< > : " / \ | ? *`) are replaced
with `_`.

### 2.2 `metadata.json` — version 2

```jsonc
{
  "version": 2,                       // format version
  "exported": "2025-04-10T14:30:00Z", // ISO 8601 export timestamp
  "songs": [
    {
      "id":     "550e8400-e29b-41d4-a716-446655440000", // UUID v4
      "title":  "Amazing Grace",
      "author": "John Newton",        // empty string when unknown
      "time":   "2024-01-15T10:00:00.000Z", // creation/modification timestamp
      "status": 0,                    // 0 = active, other values reserved
      "tags":   ["worship", "classic"],
      "file":   "Amazing Grace - John Newton.chopro"  // path inside this ZIP
    }
  ],
  "playlists": [
    {
      "title": "Sunday Service",
      "songs": [                      // ordered list of song UUIDs
        "550e8400-e29b-41d4-a716-446655440000",
        "661f9511-f30c-52e5-b827-557766551111"
      ]
    }
  ]
}
```

**`version` field values:**

| Version | Description |
|---|---|
| 1 | Original format — no `id`, no `tags`, no `playlists` in metadata |
| 2 | Current — adds `id`, `tags`, `playlists`; bodies in separate `.chopro` files |

Version 1 files are imported without tags or playlist data. Missing `id` fields
receive a freshly generated UUID on import.

### 2.3 Import behaviour

| Situation | Behaviour |
|---|---|
| Song not in library | Inserted with original UUID preserved |
| Song already present (same title + author) | User is prompted: skip / keep both / replace |
| `keepBoth` chosen | Duplicate saved as `{title} (2)` with a new UUID |
| Playlist title already exists | Songs are added to the existing playlist |
| Playlist title is new | Playlist is created, then songs are linked |
| Song was skipped during conflict | Not linked to any imported playlist |

### 2.4 Fallback import (no `metadata.json`)

If `metadata.json` is absent, CantScout scans the archive for any `.chopro`
or `.cho` file and imports each one using the ChordPro metadata-extraction
rules described in §1.4. Tags and playlists are not restored in this path.

---

## 3. BLE Transfer Wire Protocol

CantScout uses Bluetooth Low Energy to transfer songs directly between devices.
The sender acts as a **GATT peripheral**; the receiver acts as a **GATT
central**.

### 3.1 GATT profile

| Role | UUID |
|---|---|
| Service | `0000AA00-0000-1000-8000-00805F9B34FB` |
| Data characteristic (NOTIFY + READ) | `0000AA01-0000-1000-8000-00805F9B34FB` |
| Control characteristic (WRITE) | `0000AA02-0000-1000-8000-00805F9B34FB` |

The data characteristic includes a **CCCD descriptor**
(`00002902-0000-1000-8000-00805F9B34FB`, readable + writable) required for
the receiver to enable notifications via `setNotifyValue(true)`.

Advertised local name: **`CantScout`**

### 3.2 Transfer sequence

```
Receiver                            Sender
   |                                   |
   |── scan for service AA00 ─────────>|
   |<─ advertisement ──────────────────|
   |                                   |
   |── connect ──────────────────────>|
   |── discover services ────────────>|
   |── CCCD write [0x01,0x00] ────────>|  (enable notifications on AA01)
   |── write "START" to AA02 ─────────>|
   |                                   |
   |<─ chunk 0  (AA01 notify) ─────────|
   |<─ chunk 1  (AA01 notify) ─────────|
   |        …                          |
   |<─ chunk N-1 (AA01 notify) ────────|
   |<─ DONE packet (AA01 notify) ───── |
   |                                   |
   |── disconnect ────────────────────>|
```

### 3.3 Chunk format

Every notification on AA01 is a binary frame:

```
Byte 0   Byte 1   Byte 2   Byte 3   Bytes 4…
─────────────────────────────────────────────────────────────
chunk_hi chunk_lo total_hi total_lo  payload (up to 480 bytes)
```

- **chunk index** and **total chunks**: big-endian uint16
- **payload**: a contiguous slice of the gzip-compressed JSON stream
- **chunk payload size**: 480 bytes (last chunk may be shorter)

### 3.4 Done marker

End of transfer is signalled by a 4-byte notification:

```
0xFF 0xFF 0xFF 0xFF
```

### 3.5 Payload format

The reassembled payload is:

```
gzip( UTF-8 JSON )
```

The JSON structure mirrors the chopack `metadata.json` (version 2) with the
song **body inlined** instead of referencing a separate file:

```jsonc
{
  "version": 2,
  "songs": [
    {
      "id":     "550e8400-…",
      "title":  "Amazing Grace",
      "author": "John Newton",
      "time":   "2024-01-15T10:00:00.000Z",
      "status": 0,
      "tags":   ["worship"],
      "body":   "{title: Amazing Grace}\n[G]Amazing [C]grace…"
    }
  ],
  "playlists": [
    {
      "title": "Sunday Service",
      "songs": ["550e8400-…"]
    }
  ]
}
```

### 3.6 Implementation notes

- The sender broadcasts notifications with `deviceId: null` (sends to all
  subscribed centrals). This is safe because transfers are always 1-to-1.
- MTU negotiation: the receiver requests MTU 512 on Android after connecting.
  The 480-byte payload size is chosen to fit comfortably within a 512-byte ATT
  MTU (512 − 4 header − 28 ATT/L2CAP overhead ≈ 480).
- Automatic bonding (`createBond`) is disabled in the local fork of
  `ble_peripheral` (`packages/ble_peripheral/`). The song data is not
  sensitive, so BLE encryption is not required.
- Inter-chunk delay: 15 ms between notifications to avoid overflowing the
  peripheral's notification queue. On retry after a send failure a 50 ms delay
  is used.
