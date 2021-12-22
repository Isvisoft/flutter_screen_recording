import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:quiver/async.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool recording = false;
  bool paused = false;
  int _time = 0;

  requestPermissions() async {
    await PermissionHandler().requestPermissions([
      PermissionGroup.storage,
      PermissionGroup.photos,
      PermissionGroup.microphone,
    ]);
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    startTimer();
  }

  void startTimer() {
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: 1000),
      new Duration(seconds: 1),
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() => _time++);
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
          title: const Text('Flutter Screen Recording'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Time: $_time\n'),
            !recording
                ? Center(
                    child: RaisedButton(
                      child: Text("Record Screen"),
                      onPressed: () => startScreenRecord(false),
                    ),
                  )
                : Container(),
            !recording
                ? Center(
                    child: RaisedButton(
                      child: Text("Record Screen & audio"),
                      onPressed: () => startScreenRecord(true),
                    ),
                  )
                : Center(
                    child: RaisedButton(
                      child: Text("Stop Record"),
                      onPressed: () => stopScreenRecord(),
                    ),
                  ),
            if (recording && !paused)
              Center(
                child: RaisedButton(
                  child: Text("Pause"),
                  onPressed: pauseRecord,
                ),
              ),
            if (recording && paused)
              Center(
                child: RaisedButton(
                  child: Text("Resume"),
                  onPressed: resumeRecordScreen,
                ),
              )
          ],
        ),
      ),
    );
  }

  pauseRecord() {
    setState(() {
      paused = FlutterScreenRecording.pauseRecordScreen();
    });
  }

  resumeRecordScreen() {
    setState(() {
      paused = !FlutterScreenRecording.resumeRecordScreen();
    });
  }

  startScreenRecord(bool audio) async {
    bool start = false;

    if (audio) {
      start = await FlutterScreenRecording.startRecordScreenAndAudio(
        "Title",
        recordSystemAudio: true,
        disableUserAudio: false,
      );
    } else {
      start = await FlutterScreenRecording.startRecordScreen("Title");
    }

    if (start) {
      setState(() => recording = !recording);
    }

    return start;
  }

  stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    setState(() {
      recording = !recording;
    });
    print("Opening video");
    print(path);
    OpenFile.open(path);
  }
}
