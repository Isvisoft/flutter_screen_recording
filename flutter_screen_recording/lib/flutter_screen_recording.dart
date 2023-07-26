import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'dart:async';
import 'dart:io';

class FlutterScreenRecording {
  static Future<bool> startRecordScreen(String name, {String titleNotification, String messageNotification}) async{
    await _maybeStartFGS(titleNotification, messageNotification);
    final bool start = await FlutterScreenRecordingPlatform.instance.startRecordScreen(name);
    return start;
  }

  static Future<bool> startRecordScreenAndAudio(String name, {String titleNotification, String messageNotification}) async {
    //await _maybeStartFGS(titleNotification, messageNotification);
    final bool start = await FlutterScreenRecordingPlatform.instance.startRecordScreenAndAudio(name);
    return start;
  }

  static Future<bool> resumeRecordScreen() async {
    final bool resume = await FlutterScreenRecordingPlatform.instance.resumeRecordScreen();
    return resume;
  }

  static Future<bool> pauseRecordScreen() async {
    final bool pause = await FlutterScreenRecordingPlatform.instance.pauseRecordScreen();
    return pause;
  }

  static Future<String> get stopRecordScreen async {
    final String path = await FlutterScreenRecordingPlatform.instance.stopRecordScreen;
    if (!kIsWeb && Platform.isAndroid) {
      FlutterForegroundTask.stopService();
    }
    return path;
  }

  static  _maybeStartFGS(String titleNotification, String messageNotification) async {
    if (!kIsWeb && Platform.isAndroid) {

      await FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_channel_id',
          channelName: titleNotification,
          channelDescription: messageNotification,
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [
            // const NotificationButton(id: 'sendButton', text: 'Send'),
            // const NotificationButton(id: 'testButton', text: 'Test'),
          ],
        ),
        // iosNotificationOptions: const IOSNotificationOptions(
        //   showNotification: true,
        //   playSound: false,
        // ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          autoRunOnBoot: true,
          allowWifiLock: true,
        ),
        printDevLog: true,
      );
    }
  }

  static void globalForegroundService() {
    print("current datetime is ${DateTime.now()}");
  }
}
