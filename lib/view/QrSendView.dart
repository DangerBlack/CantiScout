import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../Database.dart';
import '../controller/AppLocalizations.dart';
import '../controller/QrTransferController.dart';
import '../controller/ReedSolomonCodec.dart';
import '../model/Song.dart';

enum _Status { loading, sending, error }

/// Displays an animated QR Reed-Solomon frame sequence for a playlist or song list.
///
/// The sender loops the QR frames continuously. Receivers running
/// [QrReceiveView] scan as many frames as needed and reconstruct the payload
/// once they have collected k unique shards out of n.
class QrSendView extends StatefulWidget {
  final int? playlistId;
  final String? playlistName;
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

  List<RsFrame>? _frames;
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

  Future<void> _buildPayload() async {
    try {
      List<Song> songs;
      List<(String, List<String>)> playlists = [];

      if (widget.songs != null) {
        songs = widget.songs!;
      } else if (widget.playlistId != null) {
        songs = await DBProvider.db.getAllPlaylistSongs(widget.playlistId!);
        playlists = [
          (widget.playlistName ?? '', songs.map((s) => s.id).toList())
        ];
      } else {
        songs = await DBProvider.db.getAllSongs();
        final allPlaylists = await DBProvider.db.getAllPlaylist();
        for (final pl in allPlaylists) {
          final plSongs = await DBProvider.db.getAllPlaylistSongs(pl.id);
          playlists.add((pl.title, plSongs.map((s) => s.id).toList()));
        }
      }

      if (!mounted) return;

      if (songs.isEmpty) {
        setState(() {
          _status = _Status.error;
          _errorMessage = AppLocalizations.of(context).no_songs_to_share;
        });
        return;
      }

      for (final song in songs) {
        final tags = await DBProvider.db.getTagsBySongId(song.id);
        song.setTags(tags);
      }

      if (!mounted) return;

      final Uint8List payload =
          QrTransferController.buildPayload(songs, playlists: playlists);

      final encoder = RsEncoder(payload);
      _frames = encoder.encode();
      _songCount = songs.length;

      _advanceFrame();
      setState(() => _status = _Status.sending);

      _timer = Timer.periodic(
        const Duration(milliseconds: 333),
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
    if (_frames == null || _frames!.isEmpty) return;
    final frame = _frames![_frameIndex % _frames!.length];
    setState(() {
      _currentQrData = frame.toQrData();
      _frameIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final title = widget.playlistName ?? loc.share_via_qr_default_title;
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
    final loc = AppLocalizations.of(context);
    switch (_status) {
      case _Status.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(loc.qr_preparing),
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
                child: Text(loc.shut_down),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSending(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final qrSize = MediaQuery.of(context).size.width - 48;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          loc.qr_song_count(_songCount),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          loc.qr_point_camera,
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
        if (_frames != null) ...[
          Text(
            loc.qr_frame_display(
                _frameIndex % _frames!.length + 1, _frames!.length),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _frames!.isNotEmpty
                ? (_frameIndex % _frames!.length + 1) / _frames!.length
                : 0,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          loc.qr_footer_text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }
}
