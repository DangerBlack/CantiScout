import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide CharacteristicProperties;
import 'package:permission_handler/permission_handler.dart';

import '../Database.dart';
import '../controller/BleTransferController.dart';
import '../model/Playlist.dart';
import '../model/Song.dart';

enum _Status { scope, requesting, advertising, connected, sending, done, error }

/// Sends songs (full library, a playlist, or a single song) to a nearby device
/// via BLE. The caller can pre-set a scope by passing [playlistId] / [songs].
class BleSendView extends StatefulWidget {
  /// Pre-selected playlist — skips scope selection if provided.
  final int? playlistId;
  final String? playlistName;

  /// Pre-selected song list — skips scope selection if provided.
  final List<Song>? songs;

  const BleSendView({
    Key? key,
    this.playlistId,
    this.playlistName,
    this.songs,
  }) : super(key: key);

  @override
  State<BleSendView> createState() => _BleSendViewState();
}

class _BleSendViewState extends State<BleSendView> {
  _Status _status = _Status.scope;

  // Scope selection
  bool _useLibrary = true;
  List<Playlist> _playlists = [];
  int? _chosenPlaylistId;
  String _chosenPlaylistName = '';

  // Transfer progress
  double _progress = 0.0;
  int _songCount = 0;
  int _sentChunks = 0;
  int _totalChunks = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.songs != null) {
      // Caller gave us an explicit song list — skip scope screen
      _status = _Status.requesting;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _beginTransfer(widget.songs!));
      return;
    }
    if (widget.playlistId != null) {
      _useLibrary = false;
      _chosenPlaylistId = widget.playlistId;
      _chosenPlaylistName = widget.playlistName ?? '';
    }
    _loadPlaylists();
  }

  @override
  void dispose() {
    BlePeripheral.stopAdvertising();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final list = await DBProvider.db.getAllPlaylist();
    if (mounted) setState(() => _playlists = list);
  }

  // ── Permission request ──────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    // On Android 12+ (API 31+) BLUETOOTH_SCAN/CONNECT/ADVERTISE are the runtime
    // permissions. The legacy BLUETOOTH permission is install-time and must NOT
    // be requested at runtime (it returns 'denied' and would block the check).
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return statuses.values
        .every((s) => s.isGranted || s.isLimited);
  }

  // ── Transfer orchestration ──────────────────────────────────────────────────

  Future<void> _onStartPressed() async {
    if (mounted) setState(() => _status = _Status.requesting);

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

    List<Song> songs;
    if (!_useLibrary && _chosenPlaylistId != null) {
      songs =
          await DBProvider.db.getAllPlaylistSongs(_chosenPlaylistId!);
    } else {
      songs = await DBProvider.db.getAllSongs();
    }

    if (!mounted) return;
    if (songs.isEmpty) {
      setState(() {
        _status = _Status.error;
        _errorMessage = 'Nessuna canzone da inviare.';
      });
      return;
    }

    await _beginTransfer(songs);
  }

  Future<void> _beginTransfer(List<Song> songs) async {
    if (mounted) setState(() => _songCount = songs.length);

    final chunks = BleTransferController.buildChunks(songs);
    _totalChunks = chunks.length;

    try {
      await BlePeripheral.initialize();

      // Check Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (mounted) {
          setState(() {
            _status = _Status.error;
            _errorMessage = 'Attiva il Bluetooth e riprova.';
          });
        }
        return;
      }

      // Clear any previously registered services
      await BlePeripheral.clearServices();

      await BlePeripheral.addService(
        BleService(
          uuid: BleTransferController.kServiceUuid,
          primary: true,
          characteristics: [
            BleCharacteristic(
              uuid: BleTransferController.kDataCharUuid,
              properties: [
                CharacteristicProperties.notify.index,
                CharacteristicProperties.read.index,
              ],
              permissions: [AttributePermissions.readable.index],
              descriptors: [],
            ),
            BleCharacteristic(
              uuid: BleTransferController.kControlCharUuid,
              properties: [CharacteristicProperties.write.index],
              permissions: [AttributePermissions.writeable.index],
              descriptors: [],
            ),
          ],
        ),
      );

      String? connectedDevice;

      BlePeripheral.setCharacteristicSubscriptionChangeCallback(
        (String deviceId, String charId, bool isSubscribed, String? name) {
          if (isSubscribed) {
            connectedDevice = deviceId;
            if (mounted) setState(() => _status = _Status.connected);
          }
        },
      );

      // WriteRequestCallback is synchronous — spawn async work separately
      BlePeripheral.setWriteRequestCallback(
          (String deviceId, String charId, int offset, Uint8List? value) {
        final cmd = utf8.decode(value ?? Uint8List(0));
        if (cmd == BleTransferController.kCommandStart) {
          _sendChunks(chunks, connectedDevice);
        }
        return null;
      });

      await BlePeripheral.startAdvertising(
        services: [BleTransferController.kServiceUuid],
        localName: BleTransferController.kDeviceName,
      );

      if (mounted) setState(() => _status = _Status.advertising);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _Status.error;
          _errorMessage = 'Errore Bluetooth: $e';
        });
      }
    }
  }

  Future<void> _sendChunks(List<Uint8List> chunks, String? deviceId) async {
    if (mounted) setState(() => _status = _Status.sending);

    for (int i = 0; i < chunks.length; i++) {
      try {
        await BlePeripheral.updateCharacteristic(
          characteristicId: BleTransferController.kDataCharUuid,
          value: chunks[i],
          deviceId: deviceId,
        );
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 50));
        try {
          await BlePeripheral.updateCharacteristic(
            characteristicId: BleTransferController.kDataCharUuid,
            value: chunks[i],
            deviceId: deviceId,
          );
        } catch (e) {
          if (mounted) {
            setState(() {
              _status = _Status.error;
              _errorMessage = 'Errore durante l\'invio: $e';
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _sentChunks = i + 1;
          _progress = (i + 1) / chunks.length;
        });
      }

      await Future.delayed(const Duration(milliseconds: 15));
    }

    await BlePeripheral.updateCharacteristic(
      characteristicId: BleTransferController.kDataCharUuid,
      value: BleTransferController.buildDonePacket(),
      deviceId: deviceId,
    );

    await BlePeripheral.stopAdvertising();
    if (mounted) setState(() => _status = _Status.done);
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invia canzoni')),
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
      case _Status.scope:
        return _buildScopeSelector(context);
      case _Status.requesting:
        return _buildWaiting('Verifica permessi…');
      case _Status.advertising:
        return _buildAdvertising();
      case _Status.connected:
        return _buildWaiting('Connesso! In attesa del comando…');
      case _Status.sending:
        return _buildSending();
      case _Status.done:
        return _buildDone();
      case _Status.error:
        return _buildError();
    }
  }

  Widget _buildScopeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cosa vuoi inviare?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        RadioListTile<bool>(
          title: const Text('Libreria completa'),
          value: true,
          groupValue: _useLibrary,
          onChanged: (v) => setState(() => _useLibrary = true),
        ),
        RadioListTile<bool>(
          title: const Text('Playlist'),
          value: false,
          groupValue: _useLibrary,
          onChanged: _playlists.isEmpty
              ? null
              : (v) => setState(() => _useLibrary = false),
        ),
        if (!_useLibrary && _playlists.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: DropdownButtonFormField<int>(
              value: _chosenPlaylistId,
              decoration: const InputDecoration(
                labelText: 'Seleziona playlist',
                border: OutlineInputBorder(),
              ),
              items: _playlists.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text(p.title),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                final p = _playlists.firstWhere((p) => p.id == id);
                setState(() {
                  _chosenPlaylistId = id;
                  _chosenPlaylistName = p.title;
                });
              },
            ),
          ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.bluetooth),
          label: const Text('Avvia invio'),
          onPressed:
              (!_useLibrary && _chosenPlaylistId == null) ? null : _onStartPressed,
        ),
      ],
    );
  }

  Widget _buildAdvertising() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bluetooth_searching, size: 72, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          'In attesa del ricevente…',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Apri "Ricevi via Bluetooth" sull\'altro dispositivo\ne seleziona "${BleTransferController.kDeviceName}".',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        Text('$_songCount canzoni pronte',
            style: Theme.of(context).textTheme.bodyLarge),
        if (_chosenPlaylistName.isNotEmpty)
          Text(_chosenPlaylistName,
              style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSending() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bluetooth_connected, size: 72, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Invio in corso…',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 8),
        Text(
          '$_sentChunks / $_totalChunks pacchetti  •  $_songCount canzoni',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 72, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Trasferimento completato!',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('$_songCount canzoni inviate.'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
      ],
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
          onPressed: () => setState(() => _status = _Status.scope),
          child: const Text('Riprova'),
        ),
      ],
    );
  }
}
