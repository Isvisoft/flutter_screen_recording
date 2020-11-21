import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';

class FlutterScreenRecording {
  static const MethodChannel _channel =
      const MethodChannel('flutter_screen_recording');

  /// Records the device screen, without audio, to a video file named
  /// [name].mp4 on the device.
  /// The parameters [width] and [height] (in pixels) control the dimensions
  /// of the video that
  /// is produced, and therefore also the size of the video file. The full
  /// screen area is always recorded.
  /// If either [width] or [height] is null the video file will be recorded
  /// at the full resolution of
  /// the device screen.
  ///
  /// The parameters [titleNotification] and [messageNotification] are
  /// the title and content of any notification sent to the user
  /// by the [ForegroundService] that runs on Android while the screen is being
  /// recorded.
  ///
  /// Note that on some platforms it may cause an error if the video dimensions
  /// are not multiples of ten. See the example project for code.
  static Future<bool> startRecordScreen(String name,
      {int width, int height,
      String titleNotification,
      String messageNotification}) async {
    await _maybeStartFGS(titleNotification, messageNotification);
    if( width == null || height == null) {
      width = null;
      height = null;
    }
    final bool start = await _channel.invokeMethod('startRecordScreen',
        {"name": name, "audio": false, "width": width,
          "height": height});
    return start;
  }

  /// Records the device screen, with audio, to a video file named
  /// [name].mp4 on the device. See [FlutterScreenRecoding.startRecordScreen]
  /// for information about the parameters.
  static Future<bool> startRecordScreenAndAudio(String name,
      {int width, int height , String titleNotification, String messageNotification}) async {
    await _maybeStartFGS(titleNotification, messageNotification);
    if( width == null || height == null) {
      width = null;
      height = null;
    }
    final bool start = await _channel
        .invokeMethod('startRecordScreen', {"name": name, "audio": true,
    "width": width, "height": height});
    return start;
  }

  static Future<String> get stopRecordScreen async {
    final String path = await _channel.invokeMethod('stopRecordScreen');
    if (Platform.isAndroid) {
      await FlutterForegroundPlugin.stopForegroundService();
    }
    return path;
  }

  static _maybeStartFGS(
      String titleNotification, String messageNotification) async {
    if (Platform.isAndroid) {
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
}
