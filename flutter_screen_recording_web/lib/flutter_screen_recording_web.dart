library flutter_screen_recording_web;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'interop/get_display_media.dart';

import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class WebFlutterScreenRecording extends FlutterScreenRecordingPlatform {
  late MediaStream stream;
  late String name;
  late MediaRecorder mediaRecorder;
  late Blob recordedChunks;
  late String mimeType;

  static registerWith(Registrar registrar) {
    FlutterScreenRecordingPlatform.instance = WebFlutterScreenRecording();
  }

  @override
  Future<bool> startRecordScreen(String name) async {
    return _record(name, true, false);
  }

  @override
  Future<bool> startRecordScreenAndAudio(String name) async {
    return _record(name, true, true);
  }

  Future<bool> _record(String name, bool recordVideo, bool recordAudio) async {
    try {
      var audioStream;
      if(recordAudio){
        audioStream = await navigator.getUserMedia({"audio": true});
      }
      stream = await navigator.getDisplayMedia({"audio": recordAudio, "video": recordVideo});
      this.name = name;
      if(recordAudio){
        stream.addTrack(audioStream.getAudioTracks()[0]);
      }

      if (MediaRecorder.isTypeSupported('video/mp4;codecs=h265')) {
        mimeType = 'video/mp4;codecs=h265,opus';
        print("video/mp4;codecs=h265");
      } else if (MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
        print("video/mp4;codecs=h264");
        mimeType = 'video/mp4;codecs=h264,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=h265')) {
        print("video/webm;codecs=h265");
        mimeType = 'video/webm;codecs=h265,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=h264')) {
        print("video/webm;codecs=h264");
        mimeType = 'video/webm;codecs=h264,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp9')) {
        print('video/webm;codecs=vp9');
        mimeType = 'video/webm;codecs=vp9,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp8.0')) {
        print('video/webm;codecs=vp8.0');
        mimeType = 'video/webm;codecs=vp8.0,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp8')) {
        print('video/webm;codecs=vp8');
        mimeType = 'video/webm;codecs=vp8,opus';
      } else {
        mimeType = 'video/webm';
      }

      this.mediaRecorder = new MediaRecorder(stream, {'mimeType': mimeType});

      this.mediaRecorder.addEventListener('dataavailable', (Event event) {
        print("datavailable ${event.runtimeType}");
        recordedChunks = JsObject.fromBrowserObject(event)['data'];
        this.mimeType = mimeType;
        print("blob size: ${recordedChunks.size}");
      });

      this.mediaRecorder.start();

      return true;
    } on Error catch (e) {
      print("--->" + e.toString());
      return false;
    }
  }

  @override
  Future<String> get stopRecordScreen {
    final c = new Completer<String>();
    this.mediaRecorder.addEventListener("stop", (event) {
      mediaRecorder;
      this.stream.getTracks().forEach((element) => element.stop());
      this.stream;
      final a = document.createElement("a") as AnchorElement;
      final url = Url.createObjectUrl(
          new Blob(List<dynamic>.from([recordedChunks]), mimeType));
      document.body!.append(a);
      a.style.display = "none";
      a.href = url;
      a.download = this.name;
      a.click();
      Url.revokeObjectUrl(url);

      c.complete(this.name);
    });
    mediaRecorder.stop();
    return c.future;
  }
}
