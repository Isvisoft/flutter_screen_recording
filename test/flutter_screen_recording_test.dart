import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_screen_recording');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterScreenRecording.platformVersion, '42');
  });
}
