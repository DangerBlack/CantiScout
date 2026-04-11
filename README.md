# CantScout

> A mobile songbook built for places where the internet doesn't reach.

CantScout is a free, open-source Flutter application for Scout groups and anyone
who sings together outdoors. It is designed from the ground up for **offline
use**: no server, no account, no connectivity required. Songs live entirely on
the device and travel between devices over Bluetooth.

Website: **[512b.it/cantiscout](https://512b.it/cantiscout)**

---

## The challenge

Scout outings take groups to mountain tops, cliff campsites, and forest clearings
— exactly the places where mobile coverage disappears. A traditional printed
songbook takes days to prepare, costs money to print, and is out of date the
moment a new song is added to the repertoire.

CantScout turns every member's phone into an up-to-date songbook:

- The entire library fits on the device and works with **no internet connection**.
- Songs travel between devices over **Bluetooth Low Energy** — no Wi-Fi,
  no hotspot, no cables needed.
- `.chopack` bundle files can be exchanged via messaging apps, email, or USB
  when Bluetooth is not practical.
- Chords are rendered above the lyrics at any font size, so even beginners can
  follow along with a guitar.
- Autoscroll keeps the lyrics moving while both hands stay on the instrument.

---

## Copyright and content policy

**CantScout ships with zero songs.**

The app is a blank canvas. You type your group's repertoire directly into the
editor, or import a `.chopack` file prepared by your group leader. The
developers do not distribute, host, or endorse any copyrighted material.
There is no central server and no shared song database.

Song packs exchanged between users are entirely the responsibility of those
users — the same way a text editor bears no liability for what you write in it.
This design makes CantScout structurally resilient to copyright takedown
requests.

---

## Features

- **ChordPro editor** — write and edit songs in the standard ChordPro format
  with live rendering.
- **Chord-aware renderer** — chords are placed above the correct syllable, not
  just prepended to the line; pinch to zoom.
- **Rich directive support** — key, capo, tempo, time signature, subtitle,
  verse / chorus / bridge section labels, comments, and more. See
  [docs/formats.md](docs/formats.md) for the full reference.
- **Formatting validator** — the editor flags unclosed sections, unknown
  directives, and common typos in real time.
- **Bluetooth transfer** — send a song, a playlist, or your entire library to
  a nearby device over BLE; no internet required.
- **`.chopack` bundles** — ZIP-based format that carries songs, tags, and
  playlists together. Share via any file-transfer channel.
- **QR code sharing** — share a single song as a scannable QR code.
- **PDF export** — export a playlist as a print-ready PDF carnet.
- **Playlists and tags** — organise your library by context (mass, campfire,
  evening song, …).
- **Full-text search** — find songs by title, author, or lyric fragment.
- **Multiple monospace fonts** — Inconsolata, Monofur, NotCourierSans,
  CaveatBrush, Neucha; adjustable size.
- **Autoscroll** — adjustable-speed automatic scrolling so your hands stay on
  the guitar.
- **Localized** — Italian and English; more languages welcome (see
  [docs/localization.md](docs/localization.md)).

---

## Platform

| Platform | Status  |
|----------|---------|
| Android  | Released |
| iOS      | Released |

Download links are available on the
[CantScout website](https://512b.it/cantiscout).

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/formats.md](docs/formats.md) | ChordPro subset and `.chopack` bundle format |
| [docs/ble-protocol.md](docs/ble-protocol.md) | Bluetooth Low Energy wire protocol |
| [docs/build.md](docs/build.md) | How to build the app from source |
| [docs/localization.md](docs/localization.md) | How to add or update a language |
| [docs/contributing.md](docs/contributing.md) | How to contribute |

---

## Quick start for developers

```bash
git clone <repo-url>
cd cantiscout
flutter pub get
flutter run
```

Full prerequisites and release build instructions are in
[docs/build.md](docs/build.md).

---

## License

[MIT](LICENSE) © CantScout Contributors
