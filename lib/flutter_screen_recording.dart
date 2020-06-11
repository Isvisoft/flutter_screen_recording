import 'dart:async';

import 'package:flutter/services.dart';

class FlutterScreenRecording {
  static const MethodChannel _channel = const MethodChannel('flutter_screen_recording');

  static Future<bool> startRecordScreen(String name) async {
    final bool start = await _channel.invokeMethod('startRecordScreen', {"name": name, "audio": false});
    return start;
  }

  static Future<bool> startRecordScreenAndAudio(String name) async {
    final bool start = await _channel.invokeMethod('startRecordScreen', {"name": name, "audio": true});
    return start;
  }

  static Future<String> get stopRecordScreen async {
    final String path = await _channel.invokeMethod('stopRecordScreen');
    return path;
  }
}
