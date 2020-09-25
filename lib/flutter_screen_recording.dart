import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:foreground_service/foreground_service.dart';

class FlutterScreenRecording {
  static const MethodChannel _channel = const MethodChannel('flutter_screen_recording');

  static Future<bool> startRecordScreen(String name, {String titleNotification, String messageNotification}) async {
    await _maybeStartFGS(titleNotification, messageNotification);
    final bool start = await _channel.invokeMethod('startRecordScreen', {"name": name, "audio": false});
    return start;
  }

  static Future<bool> startRecordScreenAndAudio(String name, {String titleNotification, String messageNotification}) async {
    await _maybeStartFGS(titleNotification, messageNotification);
    final bool start = await _channel.invokeMethod('startRecordScreen', {"name": name, "audio": true});
    return start;
  }

  static Future<String> get stopRecordScreen async {
    final String path = await _channel.invokeMethod('stopRecordScreen');
    if (Platform.isAndroid) {
      await ForegroundService.stopForegroundService();
    }
    return path;
  }

  static void _maybeStartFGS(String titleNotification, String messageNotification) async {
    if (Platform.isAndroid) {
      ///if the app was killed+relaunched, this function will be executed again
      ///but if the foreground service stayed alive,
      ///this does not need to be re-done
      if (!(await ForegroundService.foregroundServiceIsStarted())) {
        await ForegroundService.setServiceIntervalSeconds(5);

        //necessity of editMode is dubious (see function comments)
        await ForegroundService.notification.startEditMode();

        await ForegroundService.notification.setTitle(titleNotification);
        await ForegroundService.notification.setText(messageNotification);

        await ForegroundService.notification.finishEditMode();

        await ForegroundService.startForegroundService(_foregroundServiceFunction);
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
