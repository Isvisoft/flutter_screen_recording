library flutter_screen_recording_platform_interface;

import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel_flutter_screen_recording.dart';

abstract class FlutterScreenRecordingPlatform extends PlatformInterface {
  /// Constructs a UrlLauncherPlatform.
  FlutterScreenRecordingPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterScreenRecordingPlatform _instance =
      MethodChannelFlutterScreenRecording();

  /// The default instance of [FlutterScreenRecordingPlatform] to use.
  ///
  /// Defaults to [MethodChannelUrlLauncher].
  static FlutterScreenRecordingPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UrlLauncherPlatform] when they register themselves.
  // TODO(amirh): Extract common platform interface logic.
  // https://github.com/flutter/flutter/issues/43368
  static set instance(FlutterScreenRecordingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> startRecordScreen(String name) {
    throw UnimplementedError();
  }

  Future<bool> startRecordScreenAndAudio(String name) {
    throw UnimplementedError();
  }

  Future<String> get stopRecordScreen {
    throw UnimplementedError();
  }
}
