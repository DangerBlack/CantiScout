import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Database.dart';
import '../controller/ChopackController.dart';
import '../controller/ConflictDialog.dart';
import '../controller/FountainCodec.dart';
import '../controller/QrTransferController.dart';
import '../model/Song.dart';

enum _QrStatus { requesting, scanning, importing, done, error }

/// Receives an animated fountain-code QR sequence broadcast by [QrSendView].
///
/// Opens the device camera in continuous scan mode and feeds each unique
/// QR frame into [FountainDecoder]. Once enough unique symbols have been
/// collected the payload is reconstructed and imported automatically.
class QrReceiveView extends StatefulWidget {
  const QrReceiveView({Key? key}) : super(key: key);

  @override
  State<QrReceiveView> createState() => _QrReceiveViewState();
}

class _QrReceiveViewState extends State<QrReceiveView> {
  _QrStatus _status = _QrStatus.requesting;

  MobileScannerController? _scannerController;
  FountainDecoder? _decoder;

  final Set<int> _seenSeeds = {};
  int _decodedBlocks = 0;  // source blocks recovered by belief propagation
  int _totalBlocks = 0;

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

  // ── Permissions ─────────────────────────────────────────────────────────────

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

  // ── QR detection ─────────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_status != _QrStatus.scanning) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      _processQrData(raw);
    }
  }

  void _processQrData(String qrData) {
    final frame = FountainFrame.fromQrData(qrData);
    if (frame == null) return;

    // Skip duplicate seeds (same symbol received twice).
    if (!_seenSeeds.add(frame.seed)) return;

    // Initialise decoder from the first valid frame.
    _decoder ??= FountainDecoder(
      numBlocks: frame.numBlocks,
      blockSize: frame.data.length,
      payloadSize: frame.payloadSize,
    );

    // Reject frames that belong to a different stream.
    if (frame.numBlocks != _decoder!.numBlocks) return;

    final complete = _decoder!.addFrame(frame);

    if (mounted) {
      setState(() {
        _decodedBlocks = _decoder!.decodedCount;
        _totalBlocks = frame.numBlocks;
      });
    }

    if (complete) {
      _scannerController?.stop();
      _importPayload();
    }
  }

  // ── Import ───────────────────────────────────────────────────────────────────

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
              title: '${song.title} (2)',
              author: song.author,
              body: song.body);
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

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ricevi via QR')),
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
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Importazione in corso…'),
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
              // Overlay with scanning guide
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
                _totalBlocks == 0
                    ? 'Punta la fotocamera sul QR animato'
                    : 'Decodificati $_decodedBlocks / $_totalBlocks blocchi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _totalBlocks > 0 ? _decodedBlocks / _totalBlocks : null,
              ),
              if (_totalBlocks > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Puoi unirti in qualsiasi momento — la sequenza si ripete.',
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
          Text('Importate: $_importedCount canzoni'),
          if (_skippedCount > 0)
            Text(
              'Saltate: $_skippedCount canzoni',
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
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
                child: const Text('Apri impostazioni'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi'),
              ),
          ],
        ),
      ),
    );
  }
}
