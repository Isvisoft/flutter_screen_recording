# flutter_screen_recording_platform_interface

A common platform interface for the [`flutter_screen_recording`][1] plugin.

This interface allows platform-specific implementations of the `flutter_screen_recording`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `flutter_screen_recording`, extend
[`FlutterScreenRecordingPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`FlutterScreenRecordingPlatform` by calling
`FlutterScreenRecordingPlatform.instance = MyPlatformFlutterScreenRecording()`.

[1]: ../flutter_screen_recording
[2]: lib/flutter_screen_recording_platform_interface.dart