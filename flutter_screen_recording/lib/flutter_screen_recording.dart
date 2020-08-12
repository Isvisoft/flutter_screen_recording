import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';

class FlutterScreenRecording {
  static Future<bool> startRecordScreen(String name) {
    return FlutterScreenRecordingPlatform.instance.startRecordScreen(name);
  }

  static Future<bool> startRecordScreenAndAudio(String name) {
    return FlutterScreenRecordingPlatform.instance
        .startRecordScreenAndAudio(name);
  }

  static Future<String> get stopRecordScreen {
    return FlutterScreenRecordingPlatform.instance.stopRecordScreen;
  }
}
