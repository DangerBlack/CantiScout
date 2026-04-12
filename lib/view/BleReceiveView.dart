import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/BleTransferController.dart';
import '../controller/ChopackController.dart';
import '../controller/ConflictDialog.dart';
import '../model/Song.dart';

enum _Status { idle, scanning, deviceList, connecting, receiving, done, error }

class BleReceiveView extends StatefulWidget {
  const BleReceiveView({Key? key}) : super(key: key);

  @override
  State<BleReceiveView> createState() => _BleReceiveViewState();
}

class _BleReceiveViewState extends State<BleReceiveView> {
  _Status _status = _Status.idle;

  // Scan
  final List<ScanResult> _scanResults = [];
  StreamSubscription? _scanSubscription;

  // Transfer
  BluetoothDevice? _connectedDevice;
  StreamSubscription? _dataSubscription;
  double _progress = 0.0;
  int _receivedChunks = 0;
  int _totalChunks = 0;

  // Result
  int _importedCount = 0;
  int _skippedCount = 0;
  String _errorMessage = '';

  // Raw chunk map: index → raw packet bytes
  final Map<int, List<int>> _chunkMap = {};

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    FlutterBluePlus.stopScan();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    // Legacy BLUETOOTH permission is install-time on Android 12+ — do not
    // request it at runtime or it returns 'denied' and blocks the check.
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  // ── Scan ────────────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    if (mounted) setState(() => _status = _Status.scanning);

    final ok = await _requestPermissions();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _status = _Status.error;
        _errorMessage =
            'Permessi Bluetooth negati.\nAbilitali nelle impostazioni.';
      });
      return;
    }

    _scanResults.clear();

    // Cancel any previous scan subscription before creating a new one.
    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final r in results) {
          if (!_scanResults
              .any((e) => e.device.remoteId == r.device.remoteId)) {
            _scanResults.add(r);
          }
        }
        if (_scanResults.isNotEmpty && _status == _Status.scanning) {
          _status = _Status.deviceList;
        }
      });
    });

    await FlutterBluePlus.startScan(
      withServices: [Guid(BleTransferController.kServiceUuid)],
      timeout: const Duration(seconds: 15),
    );

    if (mounted && _status == _Status.scanning) {
      // Scan timed out, no devices found
      setState(() => _status = _Status.deviceList);
    }
  }

  // ── Connect & receive ───────────────────────────────────────────────────────

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // Stop scan and cancel its subscription before connecting.
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
    if (mounted) setState(() => _status = _Status.connecting);

    try {
      // mtu: null — skip the automatic MTU request inside connect(); we do it
      // explicitly below so there is only one MTU negotiation in the log.
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: null,
      );
      _connectedDevice = device;

      // Request larger MTU on Android for faster transfer.
      if (Platform.isAndroid) {
        await device.requestMtu(512);
      }

      final services = await device.discoverServices();

      BluetoothCharacteristic? dataChar;
      BluetoothCharacteristic? controlChar;

      for (final service in services) {
        if (service.uuid.toString().toUpperCase() ==
            BleTransferController.kServiceUuid.toUpperCase()) {
          for (final char in service.characteristics) {
            final uuid = char.uuid.toString().toUpperCase();
            if (uuid == BleTransferController.kDataCharUuid.toUpperCase()) {
              dataChar = char;
            } else if (uuid ==
                BleTransferController.kControlCharUuid.toUpperCase()) {
              controlChar = char;
            }
          }
        }
      }

      if (dataChar == null || controlChar == null) {
        if (mounted) {
          setState(() {
            _status = _Status.error;
            _errorMessage = 'Servizio BLE non trovato sul dispositivo.';
          });
        }
        return;
      }

      _chunkMap.clear();
      if (mounted) setState(() => _status = _Status.receiving);

      await dataChar.setNotifyValue(true);

      // Cancel any previous data subscription before creating a new one.
      await _dataSubscription?.cancel();
      _dataSubscription = dataChar.onValueReceived.listen((value) {
        if (BleTransferController.isDonePacket(value)) {
          _onTransferComplete();
          return;
        }
        if (value.length < 4) return;

        final (index, total) = BleTransferController.parseHeader(value);
        _chunkMap[index] = value;

        if (mounted) {
          setState(() {
            _totalChunks = total;
            _receivedChunks = _chunkMap.length;
            _progress = total > 0 ? _chunkMap.length / total : 0;
          });
        }
      });

      // Tell sender to start
      await controlChar.write(
        utf8.encode(BleTransferController.kCommandStart),
        withoutResponse: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _Status.error;
          _errorMessage = 'Errore di connessione: $e\n\n'
              'Prova a disattivare e riattivare il Bluetooth, poi riprova.';
        });
      }
    }
  }

  // ── Post-receive import ──────────────────────────────────────────────────────

  Future<void> _onTransferComplete() async {
    final payload = BleTransferController.parseChunks(_chunkMap, _totalChunks);

    if (payload == null) {
      if (mounted) {
        setState(() {
          _status = _Status.error;
          _errorMessage =
              'Dati incompleti o corrotti ($_receivedChunks / $_totalChunks pacchetti ricevuti).\nRiprova.';
        });
      }
      return;
    }

    await _connectedDevice?.disconnect();

    final songs = payload.songs;
    final playlists = payload.playlists;

    // idMap: original song ID → locally saved ID (may differ for keepBoth).
    final idMap = <String, String>{};

    // Check for conflicts
    final conflicts = <Song>[];
    final newSongs = <Song>[];
    for (final song in songs) {
      final existing =
          await DBProvider.db.getSongByTitleAuthor(song.title, song.author);
      if (existing != null) {
        conflicts.add(song);
      } else {
        newSongs.add(song);
      }
    }

    // Import non-conflicting songs, preserving original IDs and tags.
    for (final song in newSongs) {
      await DBProvider.db.newSong(song);
      final tagStrings = song.tags.map((t) => t.tag).toList();
      if (tagStrings.isNotEmpty) {
        await ChopackController.saveTags(song.id, tagStrings);
      }
      idMap[song.id] = song.id;
    }
    _importedCount = newSongs.length;

    if (conflicts.isNotEmpty && mounted) {
      final policy = await showBulkConflictDialog(context,
          conflictCount: conflicts.length);
      if (policy != null) {
        await _applyConflictPolicy(conflicts, policy, idMap);
      } else {
        _skippedCount = conflicts.length;
      }
    }

    // Create playlists and link songs using the resolved ID map.
    if (playlists.isNotEmpty) {
      await ChopackController.savePlaylists(playlists, idMap);
    }

    if (mounted) setState(() => _status = _Status.done);
  }

  Future<void> _applyConflictPolicy(
    List<Song> conflicts,
    ConflictPolicy policy,
    Map<String, String> idMap,
  ) async {
    for (final song in conflicts) {
      final tagStrings = song.tags.map((t) => t.tag).toList();
      switch (policy) {
        case ConflictPolicy.keepBoth:
          final newSong = Song.create(
              title: '${song.title} (2)', author: song.author, body: song.body);
          await DBProvider.db.newSong(newSong);
          if (tagStrings.isNotEmpty) {
            await ChopackController.saveTags(newSong.id, tagStrings);
          }
          idMap[song.id] = newSong.id;
          _importedCount++;
        case ConflictPolicy.replace:
          final existing =
              await DBProvider.db.getSongByTitleAuthor(song.title, song.author);
          if (existing != null) {
            existing.body = song.body;
            existing.author = song.author;
            await DBProvider.db.updateSong(existing);
            if (tagStrings.isNotEmpty) {
              await ChopackController.saveTags(existing.id, tagStrings);
            }
            idMap[song.id] = existing.id;
            _importedCount++;
          }
        case ConflictPolicy.skip:
          _skippedCount++;
      }
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context).receive_songs_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case _Status.idle:
        return _buildIdle();
      case _Status.scanning:
        return _buildScanning();
      case _Status.deviceList:
        return _buildDeviceList();
      case _Status.connecting:
        return _buildWaiting('Connessione in corso…');
      case _Status.receiving:
        return _buildReceiving();
      case _Status.done:
        return _buildDone();
      case _Status.error:
        return _buildError();
    }
  }

  Widget _buildIdle() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth, size: 72, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            'Ricevi canzoni via Bluetooth',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Assicurati che il dispositivo mittente\nabbia avviato l\'invio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(loc.search_devices),
            onPressed: _startScan,
          ),
        ],
      ),
    );
  }

  Widget _buildScanning() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).searching_devices),
          const SizedBox(height: 8),
          Text(
            'Assicurati che "${BleTransferController.kDeviceName}" stia trasmettendo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _scanResults.isEmpty
              ? 'Nessun dispositivo trovato'
              : 'Dispositivi trovati',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (_scanResults.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(Icons.bluetooth_disabled,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Nessun dispositivo CantScout trovato.\nAssicurati che l\'altro dispositivo stia inviando.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                  onPressed: _startScan,
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _scanResults.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final r = _scanResults[index];
                final name = r.advertisementData.advName.isNotEmpty
                    ? r.advertisementData.advName
                    : 'Dispositivo sconosciuto';
                final rssi = r.rssi;
                return ListTile(
                  leading: const Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(name),
                  subtitle:
                      Text(AppLocalizations.of(context).signal_strength(rssi)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connectToDevice(r.device),
                );
              },
            ),
          ),
        if (_scanResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).search_again),
              onPressed: _startScan,
            ),
          ),
      ],
    );
  }

  Widget _buildReceiving() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bluetooth_connected, size: 72, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Ricezione in corso…',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress > 0 ? _progress : null),
        const SizedBox(height: 8),
        if (_totalChunks > 0)
          Text(
            '$_receivedChunks / $_totalChunks pacchetti',
            style: TextStyle(color: Colors.grey[700]),
          ),
      ],
    );
  }

  Widget _buildDone() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 72, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Ricezione completata!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(loc.qr_imported_count(_importedCount)),
          if (_skippedCount > 0)
            Text(loc.ble_skipped_count(_skippedCount),
                style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.shut_down),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildError() {
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 72, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => setState(() => _status = _Status.idle),
          child: Text(loc.try_again),
        ),
      ],
    );
  }
}
