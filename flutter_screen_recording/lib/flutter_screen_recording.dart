import 'package:flutter/foundation.dart';
import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'dart:async';
import 'dart:io';

import 'package:foreground_service/foreground_service.dart';

class FlutterScreenRecording {
  static Future<bool> startRecordScreen(String name) async {
    await _maybeStartFGS();
    return FlutterScreenRecordingPlatform.instance.startRecordScreen(name);
  }

  static Future<bool> startRecordScreenAndAudio(String name) {
    return FlutterScreenRecordingPlatform.instance
        .startRecordScreenAndAudio(name);
  }

  static Future<String> get stopRecordScreen async {
    final String path = await FlutterScreenRecordingPlatform.instance.stopRecordScreen;
    if (!kIsWeb && Platform.isAndroid) {
      await ForegroundService.stopForegroundService();
    }
    return path;
  }

  static void _maybeStartFGS() async {
    if (!kIsWeb && Platform.isAndroid) {
      ///if the app was killed+relaunched, this function will be executed again
      ///but if the foreground service stayed alive,
      ///this does not need to be re-done
      if (!(await ForegroundService.foregroundServiceIsStarted())) {
        await ForegroundService.setServiceIntervalSeconds(5);

        //necessity of editMode is dubious (see function comments)
        await ForegroundService.notification.startEditMode();

        await ForegroundService.notification
            .setTitle("Example Title: ${DateTime.now()}");
        await ForegroundService.notification
            .setText("Example Text: ${DateTime.now()}");

        await ForegroundService.notification.finishEditMode();

        await ForegroundService.startForegroundService(
            _foregroundServiceFunction);
        await ForegroundService.getWakeLock();
      }

      ///this exists solely in the main app/isolate,
      ///so needs to be redone after every app kill+relaunch
      await ForegroundService.setupIsolateCommunication((data) {
        print("main received: $data");
      });
    }
  }

  static void _foregroundServiceFunction() {
    print("The current time is: ${DateTime.now()}");
    //ForegroundService.notification.setText("The time was: ${DateTime.now()}");

    if (!ForegroundService.isIsolateCommunicationSetup) {
      ForegroundService.setupIsolateCommunication((data) {
        print("bg isolate received: $data");
      });
    }

    ForegroundService.sendToPort("message from bg isolate");
  }
}
