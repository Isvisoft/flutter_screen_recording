library flutter_screen_recording_web;

import 'dart:async';
import 'dart:developer';
import 'dart:html';
import 'dart:js';
import 'dart:web_audio';

import 'package:uuid/uuid.dart';

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
  Function(String result) _onStopCallback;
  MediaStream _userMediaStream;

  AudioContext _audioContext;
  MediaStreamAudioDestinationNode _audioDestinationNode;

  //id, source
  Map<String, MediaStreamAudioSourceNode> _audioSourceNodes;

  WebFlutterScreenRecording();

  static registerWith(Registrar registrar) {
    FlutterScreenRecordingPlatform.instance = WebFlutterScreenRecording();
  }

  @override
  Future<bool> startRecordScreen(
    String outputFileName, {
    Function(String) onStop,
  }) async {
    return _startRecordScreen(
      outputFileName,
      true,
      false,
      onStop: onStop,
    );
  }

  @override
  Future<bool> startRecordScreenAndAudio(
    String outputFileName, {
    bool recordSystemAudio = true,
    bool disableUserAudio = false,
    Function(String) onStop,
  }) async {
    return _startRecordScreen(
      outputFileName,
      true,
      true,
      recordSystemAudio: recordSystemAudio,
      disableUserAudio: disableUserAudio,
      onStop: onStop,
    );
  }

  Future<bool> _startRecordScreen(
    String name,
    bool recordVideo,
    bool recordAudio, {
    bool recordSystemAudio = false,
    bool disableUserAudio = false,
    Function(String) onStop,
  }) async {
    try {
      this._onStopCallback = onStop;
      if (recordAudio) {
        _userMediaStream = await navigator.getUserMedia({"audio": true});
      }
      var displayMediaStream = await navigator.getDisplayMedia({
        "audio": recordSystemAudio,
        "video": {
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        }
      });

      stream = MediaStream([displayMediaStream.getVideoTracks()[0]]);

      this.name = name;

      if (recordAudio) {
        _audioContext = AudioContext();
        _audioDestinationNode = _audioContext.createMediaStreamDestination();
        _audioSourceNodes = {};

        if (recordSystemAudio &&
            displayMediaStream.getAudioTracks().length > 0) {
          final displayAudioStreamSource =
              _audioContext.createMediaStreamSource(
                  MediaStream([displayMediaStream.getAudioTracks()[0]]));
          displayAudioStreamSource.connectNode(_audioDestinationNode);
        }

        if (_userMediaStream.getAudioTracks().length > 0) {
          final userAudioStreamSource =
              _audioContext.createMediaStreamSource(_userMediaStream);
          userAudioStreamSource.connectNode(_audioDestinationNode);
          if (disableUserAudio) {
            _userMediaStream.getAudioTracks()[0].enabled = false;
          }
        }

        if (_audioDestinationNode.stream.getAudioTracks().length > 0) {
          stream.addTrack(_audioDestinationNode.stream.getAudioTracks()[0]);
        }
      }
      if (MediaRecorder.isTypeSupported('video/mp4')) {
        mimeType = 'video/mp4';
      } else if (MediaRecorder.isTypeSupported('video/mp4;codecs=h265')) {
        mimeType = 'video/mp4;codecs=h265,opus';
      } else if (MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
        mimeType = 'video/mp4;codecs=h264,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=h265')) {
        mimeType = 'video/webm;codecs=h265,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=h264')) {
        mimeType = 'video/webm;codecs=h264,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp9')) {
        mimeType = 'video/webm;codecs=vp9,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp8.0')) {
        mimeType = 'video/webm;codecs=vp8.0,opus';
      } else if (MediaRecorder.isTypeSupported('video/webm;codecs=vp8')) {
        mimeType = 'video/webm;codecs=vp8,opus';
      } else {
        mimeType = 'video/webm';
      }

      this.mediaRecorder = new MediaRecorder(stream, {'mimeType': mimeType});

      this.mediaRecorder.addEventListener('dataavailable', (Event event) {
        recordedChunks = JsObject.fromBrowserObject(event)['data'];
        this.mimeType = mimeType;
      });

      _onStopCompleter = new Completer<String>();

      displayMediaStream.addEventListener("inactive", (event) {
        if (mediaRecorder != null && mediaRecorder.state != "inactive") {
          stopRecordScreen;
        }
      });

      this.mediaRecorder.addEventListener("stop", _onStop);

      this.mediaRecorder.start();
      return true;
    } on Error catch (error, stackTrace) {
      print("--->" + error.toString() + stackTrace.toString());

      return false;
    }
  }

  @override
  Future<String> get stopRecordScreen {
    try {
      mediaRecorder.stop();
    } catch (error, stackTrace) {
      print("Error stopRecordScreen $error $stackTrace");
      log(
        "Error stopRecordScreen",
        error: error,
        stackTrace: stackTrace,
      );
    }
    return _onStopCompleter?.future;
  }

  void _onStop(Event event) {
    try {
      _audioSourceNodes = {};
      mediaRecorder = null;
      this.stream.getTracks().forEach((element) => element.stop());
      this.stream = null;
      _audioContext = null;
      _audioDestinationNode = null;
      _userMediaStream?.getTracks()?.forEach((track) {
        track.stop();
      });
      _userMediaStream = null;
      final downloadVideoElement = document.createElement("a") as AnchorElement;
      final url = Url.createObjectUrl(
          new Blob(List<dynamic>.from([recordedChunks]), mimeType));
      document.body.append(downloadVideoElement);
      downloadVideoElement.style.display = "none";
      downloadVideoElement.href = url;
      downloadVideoElement.download = this.name;
      downloadVideoElement.click();
      Url.revokeObjectUrl(url);
      _onStopCompleter?.complete(this.name);
      this._onStopCallback?.call(this.name);
      this._onStopCallback = null;
    } catch (error, stackTrace) {
      print("Error _onStop record \n$error\n$stackTrace");
      _onStopCompleter?.completeError(error, stackTrace);
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

  @override
  Blob getRecorded() {
    return recordedChunks;
  }

  @override
  String addAudioTrack(MediaStream audioStream) {
    try {
      final audioSourceNode =
          _audioContext.createMediaStreamSource(audioStream);
      audioSourceNode.connectNode(_audioDestinationNode);

      final id = Uuid().v4();
      _audioSourceNodes[id] = audioSourceNode;
      return id;
    } catch (error, stackTrace) {
      print("Error: Cannot add audio track\n$error\n$stackTrace");
    }
    return "";
  }

  @override
  bool removeAudioTrack(String mediaStreamAudioSourceNodeId) {
    try {
      final audioSourceNode = _audioSourceNodes[mediaStreamAudioSourceNodeId];
      audioSourceNode.disconnect(_audioDestinationNode);
      return true;
    } catch (error, stackTrace) {
      print("Error: Cannot remove audio track\n$error\n$stackTrace");
      return false;
    }
  }
}
