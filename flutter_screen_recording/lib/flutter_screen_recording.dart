import 'dart:html' hide Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';

class FlutterScreenRecording {
  static Future<bool> startRecordScreen(
    String name, {
    String titleNotification,
    String messageNotification,
    Function(String) onStop,
  }) async {
    await _maybeStartFGS(titleNotification, messageNotification);
    final bool start =
    await FlutterScreenRecordingPlatform.instance.startRecordScreen(
      name,
      onStop: onStop,
    );
    return start;
  }

  static Future<bool> startRecordScreenAndAudio(String name, {
    String titleNotification,
    String messageNotification,
    bool recordSystemAudio = true,
    bool disableUserAudio = false,
    Function(String) onStop,
  }) async {
    await _maybeStartFGS(titleNotification, messageNotification);
    final bool start =
    await FlutterScreenRecordingPlatform.instance.startRecordScreenAndAudio(
      name,
      recordSystemAudio: recordSystemAudio,
      disableUserAudio: disableUserAudio,
      onStop: onStop,
    );
    return start;
  }

  static Future<String> get stopRecordScreen async {
    final String path =
    await FlutterScreenRecordingPlatform.instance.stopRecordScreen;
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterForegroundPlugin.stopForegroundService();
    }
    return path;
  }

  static _maybeStartFGS(String titleNotification, String messageNotification) async {
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 5);
      await FlutterForegroundPlugin.setServiceMethod(globalForegroundService);
      return await FlutterForegroundPlugin.startForegroundService(
        holdWakeLock: false,
        onStarted: () async {
          print("Foreground on Started");
        },
        onStopped: () {
          print("Foreground on Stopped");
        },
        title: titleNotification,
        content: messageNotification,
        iconName: "org_thebus_foregroundserviceplugin_notificationicon",
      );
    }
  }

  static void globalForegroundService() {
    print("current datetime is ${DateTime.now()}");
  }

  static bool pauseRecordScreen() =>
      FlutterScreenRecordingPlatform.instance.pauseRecordScreen();

  static bool resumeRecordScreen() =>
      FlutterScreenRecordingPlatform.instance.resumeRecordScreen();

  static String addAudioTrack(MediaStream audioStream) {
    return FlutterScreenRecordingPlatform.instance.addAudioTrack(audioStream);
  }

  static bool removeAudioTrack(String mediaStreamAudioSourceNodeId) {
    return FlutterScreenRecordingPlatform.instance
        .removeAudioTrack(mediaStreamAudioSourceNodeId);
  }
}
