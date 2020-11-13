# flutter_screen_recording

A new Flutter plugin  make a video recording of the screen. This plug-in 
requires Android SDK 21+ and iOS 10+

## Getting Started

This plugin can be used to record the screen on Android and iOS devices. The entire screen
area is captured.

1) To start the recording

```dart
bool started = FlutterScreenRecording.startRecordScreen(videoName);
```
Or

```dart
bool started = FlutterScreenRecording.startRecordScreenAndAudio(videoName);
```
For both these methods optional parameters `width` and `height` allow the dimensions of the 
video to be
set, and therefore also the size of the video file. The default dimensions are those
of the device screen.

```
// Record screen at quarter size, ie file size reduced by x16
Size win = window.physicalSize / 4;     // Reduce size
int width = win.width ~/ 10 * 10;       // Round to multiple of 10
int height = win.height ~/ 10 * 10;
await FlutterScreenRecording.startRecordScreen("Title",
  width: width, height: height,
  titleNotification: "dsffad", messageNotification: "sdffd",
);
```

2) To stop the recording

```dart
String path = FlutterScreenRecording.stopRecordScreen;
```

## Android

Flutter_Screen_Recording does not request permissions necessary. 
You can use [Permission_handler](https://pub.dev/packages/permission_handler), a permissions 
plugin for Flutter, to query and obtain the permissions in your code.
 
Declare the following permissions in your manifest:

```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_INTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

In versions of Android beginning with version 10 a foreground service is required to record 
the screen. `flutter_screen_recording` now includes 
the [flutter foreground plugin](https://pub.dev/packages/flutter_foreground_plugin). 

## iOS

You only need add the permission message on the Info.plist 

	<key>NSPhotoLibraryUsageDescription</key>
	<string>Save video in gallery</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Save audio in video</string>
