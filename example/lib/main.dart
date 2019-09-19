import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String textBtn = "Play";
  bool recording = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      platformVersion = await FlutterScreenRecording.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Text('$textBtn'),
          onPressed: () {
            recording = !recording;
            textBtn = (recording) ? "Stop" : "Play";

            if (!recording) {
              stopScreenRecord();
            } else {
              startScreenRecord();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  startScreenRecord() async {
    String path = await FlutterScreenRecording.startRecordScreen;
    print("qqqwerrtty");
    print(path);
  }

  stopScreenRecord() async {
    await FlutterScreenRecording.stopRecordScreen;
    print("stopScreenRecord");
  }
}
