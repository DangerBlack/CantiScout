import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../Database.dart';
import '../controller/FountainCodec.dart';
import '../controller/QrTransferController.dart';
import '../model/Song.dart';

enum _Status { loading, sending, error }

/// Displays an animated QR fountain-code sequence for a playlist or song list.
///
/// The sender loops the QR frames continuously. Receivers running
/// [QrReceiveView] scan as many frames as needed and reconstruct the payload
/// once they have collected enough unique symbols.
class QrSendView extends StatefulWidget {
  /// Pre-selected playlist ID — load songs from DB when set.
  final int? playlistId;
  final String? playlistName;

  /// Explicit song list — used when a single song is shared from [SongText].
  final List<Song>? songs;

  const QrSendView({
    Key? key,
    this.playlistId,
    this.playlistName,
    this.songs,
  }) : super(key: key);

  @override
  State<QrSendView> createState() => _QrSendViewState();
}

class _QrSendViewState extends State<QrSendView> {
  _Status _status = _Status.loading;
  String _errorMessage = '';

  FountainEncoder? _encoder;
  String _currentQrData = '';
  int _frameIndex = 0;
  int _songCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _buildPayload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Payload construction ────────────────────────────────────────────────────

  Future<void> _buildPayload() async {
    try {
      List<Song> songs;
      List<(String, List<String>)> playlists = [];

      if (widget.songs != null) {
        songs = widget.songs!;
      } else if (widget.playlistId != null) {
        songs =
            await DBProvider.db.getAllPlaylistSongs(widget.playlistId!);
        playlists = [
          (
            widget.playlistName ?? '',
            songs.map((s) => s.id).toList(),
          )
        ];
      } else {
        songs = await DBProvider.db.getAllSongs();
        final allPlaylists = await DBProvider.db.getAllPlaylist();
        for (final pl in allPlaylists) {
          final plSongs =
              await DBProvider.db.getAllPlaylistSongs(pl.id);
          playlists.add((pl.title, plSongs.map((s) => s.id).toList()));
        }
      }

      if (!mounted) return;

      if (songs.isEmpty) {
        setState(() {
          _status = _Status.error;
          _errorMessage = 'Nessuna canzone da condividere.';
        });
        return;
      }

      // Load tags for each song (required for the payload).
      for (final song in songs) {
        final tags = await DBProvider.db.getTagsBySongId(song.id);
        song.setTags(tags);
      }

      if (!mounted) return;

      final Uint8List payload =
          QrTransferController.buildPayload(songs, playlists: playlists);

      _encoder = FountainEncoder(payload);
      _songCount = songs.length;

      // Generate first frame immediately, then start the timer.
      _advanceFrame();
      setState(() => _status = _Status.sending);

      _timer = Timer.periodic(
        const Duration(milliseconds: 333), // 3 fps
        (_) {
          if (mounted) _advanceFrame();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _Status.error;
          _errorMessage = 'Errore: $e';
        });
      }
    }
  }

  void _advanceFrame() {
    final frame = _encoder!.next();
    setState(() {
      _currentQrData = frame.toQrData();
      _frameIndex++;
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = widget.playlistName ?? 'Condividi via QR';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
      case _Status.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparazione…'),
            ],
          ),
        );

      case _Status.sending:
        return _buildSending(context);

      case _Status.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSending(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.width - 48;
    final enc = _encoder!;
    final numBlocks = enc.numBlocks;
    final cycleFrame = ((_frameIndex - 1) % numBlocks) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$_songCount ${_songCount == 1 ? 'canzone' : 'canzoni'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Punta la fotocamera su questo schermo',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: QrImageView(
            data: _currentQrData,
            version: QrVersions.auto,
            size: qrSize,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Frame $cycleFrame / $numBlocks',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: cycleFrame / numBlocks),
        const SizedBox(height: 16),
        Text(
          'La sequenza si ripete continuamente.\n'
          'I riceventi possono unirsi in qualsiasi momento.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }
}
