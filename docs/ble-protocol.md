# Bluetooth Low Energy Transfer Protocol

CantScout uses Bluetooth Low Energy (BLE) to transfer songs directly between
devices without any internet connection. The sending device acts as a **GATT
peripheral**; the receiving device acts as a **GATT central**.

Both Android and iOS are supported. Both devices must have the app open in the
foreground during transfer.

---

## Transfer scopes

A transfer can carry:

- A single song (initiated from the song view)
- A single playlist
- The entire library

---

## GATT profile

| Role | UUID |
|------|------|
| Service | `0000AA00-0000-1000-8000-00805F9B34FB` |
| Data characteristic — NOTIFY + READ | `0000AA01-0000-1000-8000-00805F9B34FB` |
| Control characteristic — WRITE | `0000AA02-0000-1000-8000-00805F9B34FB` |

The data characteristic exposes a **CCCD descriptor**
(`00002902-0000-1000-8000-00805F9B34FB`, readable + writable) required for the
receiver to enable notifications via `setNotifyValue(true)`.

Advertised local name: **`CantScout`**

---

## Transfer sequence

```
Receiver                              Sender
   |                                     |
   |── scan for service AA00 ──────────> |
   |<── advertisement ─────────────────  |
   |                                     |
   |── connect ────────────────────────> |
   |── discover services ──────────────> |
   |── CCCD write [0x01, 0x00] ────────> |  (enable notifications on AA01)
   |── write "START" to AA02 ──────────> |
   |                                     |
   |<── chunk 0  (AA01 notify) ─────────  |
   |<── chunk 1  (AA01 notify) ─────────  |
   |         …                           |
   |<── chunk N-1 (AA01 notify) ────────  |
   |<── DONE packet (AA01 notify) ──────  |
   |                                     |
   |── disconnect ────────────────────── |
```

---

## Chunk format

Every notification on the data characteristic is a binary frame:

```
Byte 0   Byte 1   Byte 2   Byte 3   Bytes 4 …
─────────────────────────────────────────────────────────
chunk_hi chunk_lo total_hi total_lo  payload (≤ 480 bytes)
```

- **chunk index** and **total chunks**: big-endian uint16, zero-based index.
- **payload**: a contiguous slice of the gzip-compressed JSON stream.
- **payload size**: up to 480 bytes per chunk (the last chunk may be shorter).

---

## End-of-transfer marker

Transfer completion is signalled by a 4-byte notification:

```
0xFF 0xFF 0xFF 0xFF
```

---

## Payload format

After reassembly, the binary stream is:

```
gzip( UTF-8 JSON )
```

The JSON mirrors the `.chopack` `metadata.json` v2 schema (see
[formats.md](formats.md)) with one difference: the song body is **inlined**
instead of referencing a separate file.

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

---

## Conflict resolution

Songs that already exist in the receiver's library (matched by title + author)
trigger the same conflict dialog used during `.chopack` import:
**skip / keep both / replace**.

---

## Implementation notes

- **MTU**: the receiver requests MTU 512 on Android after connecting. The
  480-byte payload size fits within a 512-byte ATT MTU after header overhead.
- **Pacing**: the sender waits 15 ms between notifications to avoid overflowing
  the peripheral's notification queue. On send failure the delay increases to
  50 ms for the retry.
- **Encryption**: automatic BLE bonding (`createBond`) is disabled. Song data
  is not sensitive, so link-layer encryption is not required.
- **`ble_peripheral` fork**: the project vendors a lightly patched copy of
  `ble_peripheral` under `packages/ble_peripheral/` to disable automatic
  bonding on Android.
- **Throughput estimate**: a 200-song library ≈ 200 KB compressed →
  ~417 chunks → ~6 seconds at 15 ms/chunk.

---

## Known limitations

- Both devices must keep the app in the **foreground** throughout the transfer
  (iOS restricts background BLE advertising).
- There is no chunk retransmission. A failed transfer shows an error with a
  retry option that restarts from the beginning.
- Libraries larger than ~500 songs display a warning about expected transfer
  time.
