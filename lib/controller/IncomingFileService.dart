import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Bridges native file-open intents (Android ACTION_VIEW, iOS openURL)
/// to a Dart broadcast stream.
///
/// Call [init] once after [WidgetsFlutterBinding.ensureInitialized].
/// Subscribe to [fileStream] to receive incoming file paths.
class IncomingFileService {
  static const _channel = MethodChannel('cantiscout/file_intent');

  IncomingFileService._();
  static final instance = IncomingFileService._();

  final _controller = StreamController<String>.broadcast();

  Stream<String> get fileStream => _controller.stream;

  void init() {
    // Warm-start: native side invokes this when a new file intent arrives
    // while the app is already running.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewFile') {
        final path = call.arguments as String?;
        if (path != null) _controller.add(path);
      }
    });

    // Cold-start: query the file path that launched the app.
    // addPostFrameCallback ensures the platform channel is fully wired
    // before we call the native side (critical on iOS).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final path = await _channel.invokeMethod<String>('getInitialFile');
        if (path != null) _controller.add(path);
      } catch (_) {
        // Platform does not implement this method — ignore.
      }
    });
  }
}
