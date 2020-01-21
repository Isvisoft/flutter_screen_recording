import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:quiver/async.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String textBtn = "Play";
  bool recording = false;
  int _time = 0;

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

    startTimer();
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void startTimer() {
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: 1000),
      new Duration(seconds: 1),
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _time++;
      });
    });

    sub.onDone(() {
      print("Done");
      sub.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Text('Running on: $_platformVersion\n'),
            Text('Time: $_time\n'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Text('$textBtn'),
          onPressed: () async {
            if (recording) {
              stopScreenRecord();
            } else {

              var start = await startScreenRecord();
              if(start){
                recording = !recording;
                textBtn = (recording) ? "Stop" : "Play";
              }
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  startScreenRecord() async {
    print("before");
    bool start = await FlutterScreenRecording.startRecordScreen("Title");
    print("after");
    print(start);
    return start;
  }

  stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    print(path);
  }
}
