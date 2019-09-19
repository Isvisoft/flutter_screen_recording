import 'dart:async';

import 'package:flutter/services.dart';

class FlutterScreenRecording {
  static const MethodChannel _channel =
      const MethodChannel('flutter_screen_recording');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get startRecordScreen async {
    final String path = await _channel.invokeMethod('startRecordScreen');
    return path;
  }

  static Future<void> get stopRecordScreen async {
    return await _channel.invokeMethod('stopRecordScreen');
  }
}
