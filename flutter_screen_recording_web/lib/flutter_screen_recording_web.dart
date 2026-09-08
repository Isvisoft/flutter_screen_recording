library flutter_screen_recording_web;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'interop/get_display_media.dart';

import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class WebFlutterScreenRecording extends FlutterScreenRecordingPlatform {
  MediaStream? stream;
  String? name;
  MediaRecorder? mediaRecorder;
  Blob? recordedChunks;
  String? mimeType;

  static registerWith(Registrar registrar) {
    FlutterScreenRecordingPlatform.instance = WebFlutterScreenRecording();
  }

  @override
  Future<bool> startRecordScreen(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    return _record(name, true, false);
  }

  @override
  Future<bool> startRecordScreenAndAudio(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    return _record(name, true, true);
  }

  Future<bool> _record(String name, bool recordVideo, bool recordAudio) async {
    try {
      var audioStream;

      final captureOptions = [
        {
          "video": {
            "displaySurface": 'browser',
          },
          "preferCurrentTab": true,
          "selfBrowserSurface": 'include',
          "surfaceSwitching": 'include',
        },
        {
          "video": {
            "displaySurface": 'browser',
          },
          "preferCurrentTab": true,
          "selfBrowserSurface": 'include',
        },
      ];

      for (var i = 0; i < captureOptions.length; i++) {
        try {
          stream = await navigator.getDisplayMedia(captureOptions[i]);
          break;
        } catch (e) {
          if (i == captureOptions.length - 1) {
            rethrow;
          }
        }
      }

      if (recordAudio) {
        audioStream = await navigator.getUserMedia({"audio": true});
        if (audioStream.getAudioTracks().isNotEmpty) {
          stream!.addTrack(audioStream.getAudioTracks()[0]);
        }
      }

      this.name = name;
      mimeType = _getSupportedMimeType();

      this.mediaRecorder = new MediaRecorder(stream!, {'mimeType': mimeType});

      this.mediaRecorder!.addEventListener('dataavailable', (Event event) {
        print("datavailable ${event.runtimeType}");
        recordedChunks = JsObject.fromBrowserObject(event)['data'];
        print("blob size: ${recordedChunks?.size ?? 'empty'}");
      });

      this.stream!.getVideoTracks()[0].addEventListener('ended', (Event event) {
        //If user stop sharing screen, stop record
        stopRecordScreen;
      });

      this.mediaRecorder!.start();

      return true;
    } catch (e) {
      print("--->$e");
      return false;
    }
  }

  String _getSupportedMimeType() {
    const preferredMimeTypes = [
      'video/mp4',
      'video/webm;codecs=vp9',
      'video/webm;codecs=vp8',
      'video/webm;codecs=h264',
      'video/webm',
    ];

    for (final type in preferredMimeTypes) {
      if (MediaRecorder.isTypeSupported(type)) {
        print(type);
        return type;
      }
    }

    return 'video/webm';
  }

  String _getDownloadName() {
    final currentName = name?.isNotEmpty == true ? name! : 'recording';
    final extension = mimeType?.startsWith('video/mp4') == true ? '.mp4' : '.webm';
    final lowerName = currentName.toLowerCase();

    if (lowerName.endsWith('.mp4') || lowerName.endsWith('.webm')) {
      return '${currentName.substring(0, currentName.lastIndexOf('.'))}$extension';
    }

    return '$currentName$extension';
  }

  @override
  Future<String> get stopRecordScreen {
    final c = new Completer<String>();
    this.mediaRecorder!.addEventListener("stop", (event) {
      mediaRecorder = null;
      this.stream!.getTracks().forEach((element) => element.stop());
      this.stream = null;
      final a = document.createElement("a") as AnchorElement;
      final url = Url.createObjectUrl(new Blob(List<dynamic>.from([recordedChunks]), mimeType));
      final downloadName = _getDownloadName();
      document.body!.append(a);
      a.style.display = "none";
      a.href = url;
      a.download = downloadName;
      a.click();
      Url.revokeObjectUrl(url);

      c.complete(downloadName);
    });
    mediaRecorder!.stop();
    return c.future;
  }
}
