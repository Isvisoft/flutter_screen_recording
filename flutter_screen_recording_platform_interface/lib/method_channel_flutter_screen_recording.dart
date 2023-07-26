import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_screen_recording_platform_interface.dart';

class MethodChannelFlutterScreenRecording
    extends FlutterScreenRecordingPlatform {
  static const MethodChannel _channel =
      const MethodChannel('flutter_screen_recording');

  Future<bool> startRecordScreen(String name) async {
    final bool start = await _channel
        .invokeMethod('startRecordScreen', {"name": name, "audio": false});
    return start;
  }

  Future<bool> startRecordScreenAndAudio(String name) async {
    final bool start = await _channel
        .invokeMethod('startRecordScreen', {"name": name, "audio": true});
    return start;
  }

  Future<bool> resumeRecordScreen() async {
    final bool resume = await _channel
        .invokeMethod('resumeRecordScreen');
    return resume;
  }

  Future<bool> pauseRecordScreen() async {
    final bool pause = await _channel
        .invokeMethod('pauseRecordScreen');
    return pause;
  }

  Future<String> get stopRecordScreen async {
    final String path = await _channel.invokeMethod('stopRecordScreen');
    return path;
  }
}
