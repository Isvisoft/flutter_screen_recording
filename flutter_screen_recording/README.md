# flutter_screen_recording

A new Flutter plugin for record the screen. This plug-in requires Android SDK 21+ and iOS 10+



## Getting Started

This plugin can be used for record the screen on Android and iOS devices.

1) For start the recording

```dart
bool started = FlutterScreenRecording.startRecordScreen(videoName);
```
Or

```dart
bool started = FlutterScreenRecording.startRecordScreenAndAudio(videoName);
```

2) For stop the recording

```dart
String path = FlutterScreenRecording.stopRecordScreen;
```

## Android

Flutter_Screen_Recorder do not request permissions necessary. You can use [Permission_handler](https://pub.dev/packages/permission_handler), a permissions plugin for Flutter.
Require and add the following permissions in your manifest:

```java
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_INTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## iOS

You only need add the permission message on the Info.plist 

	<key>NSPhotoLibraryUsageDescription</key>
	<string>Save video in gallery</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Save audio in video</string>
	
## Web
This plugin compiles for the web platform since version 2.0.0.


