import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/ChopackController.dart';
import '../controller/ConflictDialog.dart';
import '../controller/QrTransferController.dart';
import '../controller/ReedSolomonCodec.dart';
import '../model/Song.dart';

enum _QrStatus { requesting, scanning, importing, done, error }

/// Receives an animated Reed-Solomon QR sequence broadcast by [QrSendView].
///
/// Opens the device camera in continuous scan mode and feeds each unique
/// QR shard into [RsDecoder]. Once k unique shards have been collected
/// the payload is reconstructed and imported automatically.
class QrReceiveView extends StatefulWidget {
  const QrReceiveView({Key? key}) : super(key: key);

  @override
  State<QrReceiveView> createState() => _QrReceiveViewState();
}

class _QrReceiveViewState extends State<QrReceiveView> {
  _QrStatus _status = _QrStatus.requesting;

  MobileScannerController? _scannerController;
  RsDecoder? _decoder;

  final Set<int> _seenShards = {};
  int _receivedShards = 0;
  int _neededShards = 0;
  int _totalShards = 0;

  int _importedCount = 0;
  int _skippedCount = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      setState(() => _status = _QrStatus.scanning);
    } else {
      setState(() {
        _status = _QrStatus.error;
        _errorMessage =
            'Permesso fotocamera negato.\nAbilitalo nelle impostazioni.';
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_status != _QrStatus.scanning) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      _processQrData(raw);
    }
  }

  void _processQrData(String qrData) {
    final frame = RsFrame.fromQrData(qrData);
    if (frame == null) return;

    if (!_seenShards.add(frame.shardIndex)) return;

    _decoder ??= RsDecoder(
      n: frame.numBlocks,
      k: frame.minBlocks,
      blockSize: frame.data.length,
      payloadSize: frame.payloadSize,
    );

    if (frame.numBlocks != _decoder!.n) return;

    final complete = _decoder!.addFrame(frame);

    if (mounted) {
      setState(() {
        _receivedShards = _decoder!.receivedCount;
        _neededShards = _decoder!.k;
        _totalShards = frame.numBlocks;
      });
    }

    if (complete) {
      _scannerController?.stop();
      _importPayload();
    }
  }

  Future<void> _importPayload() async {
    if (!mounted) return;
    setState(() => _status = _QrStatus.importing);

    final raw = _decoder!.reconstruct();
    if (raw == null) {
      if (mounted) {
        setState(() {
          _status = _QrStatus.error;
          _errorMessage = 'Errore nella ricostruzione dei dati.';
        });
      }
      return;
    }

    final parsed = QrTransferController.parsePayload(raw);
    if (parsed == null) {
      if (mounted) {
        setState(() {
          _status = _QrStatus.error;
          _errorMessage = 'Formato dati non riconosciuto.';
        });
      }
      return;
    }

    final songs = parsed.songs;
    final playlists = parsed.playlists;
    final idMap = <String, String>{};

    final conflicts = <Song>[];
    final newSongs = <Song>[];
    for (final song in songs) {
      final existing =
          await DBProvider.db.getSongByTitleAuthor(song.title, song.author);
      (existing != null ? conflicts : newSongs).add(song);
    }

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
      final policy = await showBulkConflictDialog(
        context,
        conflictCount: conflicts.length,
        newCount: newSongs.length,
      );
      if (policy != null) {
        await _applyConflictPolicy(conflicts, policy, idMap);
      } else {
        _skippedCount = conflicts.length;
      }
    }

    if (playlists.isNotEmpty) {
      await ChopackController.savePlaylists(playlists, idMap);
    }

    if (mounted) setState(() => _status = _QrStatus.done);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).receive_via_qr)),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case _QrStatus.requesting:
        return const Center(child: CircularProgressIndicator());

      case _QrStatus.scanning:
        return _buildScanning(context);

      case _QrStatus.importing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context).qr_importing),
            ],
          ),
        );

      case _QrStatus.done:
        return _buildDone(context);

      case _QrStatus.error:
        return _buildError(context);
    }
  }

  Widget _buildScanning(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController!,
                onDetect: _onDetect,
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.withAlpha(178),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _neededShards == 0
                    ? 'Punta la fotocamera sul QR animato'
                    : 'Shards: $_receivedShards / $_neededShards (di $_totalShards total)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    _neededShards > 0 ? _receivedShards / _neededShards : null,
              ),
              if (_neededShards > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Ogni $_neededShards shard basta per ricostruire i dati.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
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
            Text(
              loc.ble_skipped_count(_skippedCount),
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.shut_down),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            if (_status == _QrStatus.error &&
                _errorMessage.contains('fotocamera'))
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: Text(loc.open_settings),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.shut_down),
              ),
          ],
        ),
      ),
    );
  }
}
