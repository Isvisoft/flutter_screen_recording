import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_screen_recording_platform_interface.dart';

class MethodChannelFlutterScreenRecording
    extends FlutterScreenRecordingPlatform {
  static const MethodChannel _channel =
      const MethodChannel('flutter_screen_recording');

  Future<bool> startRecordScreen(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    final bool start = await _channel.invokeMethod('startRecordScreen', {
      "name": name,
      "audio": false,
      "title": notificationTitle,
      "message": notificationMessage,
    });
    return start;
  }

  Future<bool> startRecordScreenAndAudio(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    final bool start = await _channel.invokeMethod('startRecordScreen', {
      "name": name,
      "audio": true,
      "title": notificationTitle,
      "message": notificationMessage,
    });
    return start;
  }

  Future<String> get stopRecordScreen async {
    final String path = await _channel.invokeMethod('stopRecordScreen');
    return path;
  }
}
