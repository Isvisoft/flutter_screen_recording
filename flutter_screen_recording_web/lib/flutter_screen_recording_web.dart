library flutter_screen_recording_web;

import 'dart:async';
import 'dart:developer';
import 'dart:html';
import 'dart:js';
import 'dart:web_audio';

import 'interop/get_display_media.dart';

import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class WebFlutterScreenRecording extends FlutterScreenRecordingPlatform {
  MediaStream stream;
  String name;
  MediaRecorder mediaRecorder;
  Blob recordedChunks;
  String mimeType;
  Completer<String> _onStopCompleter;

  static registerWith(Registrar registrar) {
    FlutterScreenRecordingPlatform.instance = WebFlutterScreenRecording();
  }

  @override
  Future<bool> startRecordScreen(String name) async {
    return _record(name, true, false);
  }

  @override
  Future<bool> startRecordScreenAndAudio(
    String name, {
    bool recordSystemAudio = true,
    bool disableUserAudio = false,
  }) async {
    return _record(
      name,
      true,
      true,
      recordSystemAudio: recordSystemAudio,
      disableUserAudio: disableUserAudio,
    );
  }

  Future<bool> _record(
    String name,
    bool recordVideo,
    bool recordAudio, {
    bool recordSystemAudio = false,
    bool disableUserAudio = false,
  }) async {
    try {
      var userMediaStream;
      if (recordAudio) {
        userMediaStream = await navigator.getUserMedia({"audio": true});
      }
      var displayMediaStream = await navigator
          .getDisplayMedia({"audio": recordSystemAudio, "video": recordVideo});

      stream = MediaStream([displayMediaStream.getVideoTracks()[0]]);

      this.name = name;

      if (recordAudio) {
        var _audioContext = AudioContext();
        var _audioDestinationNode =
            _audioContext.createMediaStreamDestination();

        if (recordSystemAudio &&
            displayMediaStream.getAudioTracks().length > 0) {
          final displayAudioStreamSource =
              _audioContext.createMediaStreamSource(
                  MediaStream([displayMediaStream.getAudioTracks()[0]]));
          displayAudioStreamSource.connectNode(_audioDestinationNode);
        }

        if (userMediaStream.getAudioTracks().length > 0) {
          final userAudioStreamSource =
              _audioContext.createMediaStreamSource(userMediaStream);
          userAudioStreamSource.connectNode(_audioDestinationNode);
          if (disableUserAudio) {
            userMediaStream.getAudioTracks()[0].enabled = false;
          }
        }

        if (_audioDestinationNode.stream.getAudioTracks().length > 0) {
          stream.addTrack(_audioDestinationNode.stream.getAudioTracks()[0]);
        }
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
        print("blob size: ${recordedChunks?.size ?? 'empty'}");
      });

      _onStopCompleter = new Completer<String>();

      displayMediaStream.addEventListener("inactive", (event) async {
        if (mediaRecorder != null && mediaRecorder.state != "inactive") {
          final result = await stopRecordScreen;
        }
      });

      this.mediaRecorder.addEventListener("stop", _onStop);

      this.mediaRecorder.start();

      return true;
    } on Error catch (e, s) {
      print("--->_record\n" + e.toString() + s.toString());

      return false;
    }
  }

  @override
  Future<String> get stopRecordScreen {
    mediaRecorder.stop();
    return _onStopCompleter?.future;
  }

  void _onStop(Event event) {
    try {
      print("xxx_onstop");
      mediaRecorder = null;
      this.stream.getTracks().forEach((element) => element.stop());
      this.stream = null;
      final a = document.createElement("a") as AnchorElement;
      final url = Url.createObjectUrl(
          new Blob(List<dynamic>.from([recordedChunks]), mimeType));
      document.body.append(a);
      a.style.display = "none";
      a.href = url;
      a.download = this.name;
      a.click();
      Url.revokeObjectUrl(url);
      _onStopCompleter?.complete(this.name);
    } catch (ex, s) {
      print("Error _onStop\n$ex\n$s");
      _onStopCompleter?.completeError(ex, s);
    }
  }

  @override
  bool pauseRecordScreen() {
    try {
      mediaRecorder.pause();
      return true;
    } catch (error, stackTrace) {
      print(
          "Error: Cannot pauseRecordScreen\n${error.toString()}\n${stackTrace.toString()}");
      return false;
    }
  }

  @override
  bool resumeRecordScreen() {
    try {
      mediaRecorder.resume();
      return true;
    } catch (error, stackTrace) {
      print(
          "Error: Cannot resumeRecordScreen\n${error.toString()}\n${stackTrace.toString()}");
      return false;
    }
  }
}
