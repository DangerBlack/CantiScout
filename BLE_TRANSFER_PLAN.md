# BLE Song Transfer — Implementation Plan

## Goal
Enable offline, cross-platform (Android ↔ iOS) song transfer between devices using
Bluetooth Low Energy (BLE). Both devices must have the app installed.

## Transfer Scopes
- Full library
- Selected playlist
- Single song (entry point from SongText view, same flow)

---

## Architecture

### Packages Added
| Package | Version | Role |
|---|---|---|
| `flutter_blue_plus` | ^1.35.5 | Central role — receiver: scan, connect, receive |
| `ble_peripheral` | ^2.4.0 | Peripheral role — sender: advertise, serve data |
| `permission_handler` | ^11.3.0 | Runtime BLE permissions on Android |

### GATT Service Layout
- **Service UUID**: `0000AA00-0000-1000-8000-00805F9B34FB`
- **Data Characteristic** `0000AA01-...` — NOTIFY: sender pushes chunks to receiver
- **Control Characteristic** `0000AA02-...` — WRITE: receiver sends commands to sender

### Wire Protocol

#### Chunk Packet (binary, sent via NOTIFY)
```
[byte 0-1] chunk index  — uint16 big-endian, 0-based
[byte 2-3] total chunks — uint16 big-endian
[byte 4…]  payload      — raw UTF-8 JSON fragment
```

#### DONE Marker
`[0xFF, 0xFF, 0xFF, 0xFF]` — 4 bytes, signals end of transfer

#### Payload (reassembled JSON)
```json
{
  "version": 1,
  "songs": [
    {"id":"…","title":"…","author":"…","body":"…","time":"…","status":0}
  ]
}
```

#### Chunk Size
- Payload per chunk: 480 bytes (safe on both Android MTU-512 and iOS MTU-185 after negotiation)
- 200-song library ≈ 200 KB → ~417 chunks → ~6 s at 15 ms/chunk pace

### Protocol Flow
1. **Sender** advertises with service UUID, name `CantScout`
2. **Receiver** scans, shows device list, user selects sender
3. Receiver connects, requests MTU 512 (Android), subscribes to DATA char
4. Receiver writes `"START"` to CONTROL char
5. Sender sends all chunks sequentially (15 ms pace), each via NOTIFY
6. Sender sends DONE marker
7. Receiver reassembles, imports songs with conflict resolution

---

## Files

### New Files
| File | Purpose |
|---|---|
| `lib/controller/BleTransferController.dart` | Protocol constants, chunking, reassembly |
| `lib/view/BleSendView.dart` | Sender UI: scope selection, advertising, progress |
| `lib/view/BleReceiveView.dart` | Receiver UI: scan, connect, receive, import |

### Modified Files
| File | Change |
|---|---|
| `pubspec.yaml` | Add three packages |
| `android/app/src/main/AndroidManifest.xml` | Add BLE permissions |
| `ios/Runner/Info.plist` | Add Bluetooth usage descriptions |
| `lib/view/SongUlStateless.dart` | Add "Invia/Ricevi via Bluetooth" to FAB bottom sheet |
| `lib/view/SongUlPlaylistStateless.dart` | Add Bluetooth send action to AppBar |

---

## Permissions

### Android (`AndroidManifest.xml`)
```xml
<!-- Legacy (Android ≤ 11) -->
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30"/>
<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
```

### iOS (`Info.plist`)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Utilizziamo il Bluetooth per trasferire canzoni con altri dispositivi.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Utilizziamo il Bluetooth per inviare canzoni ad altri dispositivi.</string>
```

---

## UX Flow

### Sender
1. Opens song list or playlist → taps "Invia via Bluetooth"
2. BleSendView opens with scope selector (library / playlist)
3. Taps "Avvia invio" → app advertises → "In attesa del ricevente…"
4. Receiver connects → "Connesso, invio in corso…" + progress bar
5. Completion → "Trasferite N canzoni"

### Receiver
1. Taps "Ricevi via Bluetooth" in song list FAB menu
2. BleReceiveView scans (15 s timeout), shows device list
3. User taps `CantScout` device → connects → progress bar
4. Conflict resolution dialog for duplicates (Salta / Mantieni entrambe / Sostituisci tutto)
5. Success snackbar with count

---

## Known Limitations
- Both apps must be in foreground during transfer (iOS background BLE advertising restricted)
- v1 has no chunk retransmission — missing chunks show an error with retry option
- Libraries > 30 MB may take > 1 minute (show warning if > 500 songs)
