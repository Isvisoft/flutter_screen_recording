library flutter_screen_recording_web;

import 'dart:async';
import 'dart:html';

import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'interop/get_display_media.dart';
import 'src/recording_format.dart';

class WebFlutterScreenRecording extends FlutterScreenRecordingPlatform {
  MediaStream? stream;
  String? name;
  MediaRecorder? mediaRecorder;
  String? mimeType;

  final List<Blob> _recordedChunks = <Blob>[];
  MediaStream? _audioStream;
  Completer<String>? _stopCompleter;
  bool _starting = false;
  bool _recordingFailed = false;

  static registerWith(Registrar registrar) {
    FlutterScreenRecordingPlatform.instance = WebFlutterScreenRecording();
  }

  @override
  Future<bool> startRecordScreen(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    return _record(name, false);
  }

  @override
  Future<bool> startRecordScreenAndAudio(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    return _record(name, true);
  }

  Future<bool> _record(String name, bool recordAudio) async {
    if (_starting || mediaRecorder != null) {
      return false;
    }
    _starting = true;
    _recordedChunks.clear();
    _stopCompleter = null;
    _recordingFailed = false;
    mimeType = null;

    try {
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
        _audioStream = await navigator.getUserMedia({"audio": true});
        final audioTracks = _audioStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          stream!.addTrack(audioTracks.first);
        }
      }

      this.name = name;
      final recorder = _startRecorder(stream!);
      mediaRecorder = recorder;
      _stopCompleter = Completer<String>();

      // Register now, rather than only when stopRecordScreen is called: the
      // browser can also stop the recorder when screen sharing ends.
      recorder.addEventListener('stop', (Event event) {
        _finishRecording(recorder);
      });
      recorder.addEventListener('error', (Event event) {
        if (identical(mediaRecorder, recorder)) {
          _recordingFailed = true;
          print('Screen recording failed: $event');
        }
      });
      stream!.getVideoTracks().first.addEventListener('ended', (Event event) {
        if (identical(mediaRecorder, recorder)) {
          stopRecordScreen;
        }
      });

      return true;
    } catch (e) {
      _releaseStreams();
      mediaRecorder = null;
      _recordedChunks.clear();
      print('Unable to start screen recording: $e');
      return false;
    } finally {
      _starting = false;
    }
  }

  MediaRecorder _startRecorder(MediaStream recordingStream) {
    return createRecorderForSupportedFormat<MediaRecorder>(
      hasAudio: recordingStream.getAudioTracks().isNotEmpty,
      isTypeSupported: MediaRecorder.isTypeSupported,
      createAndStart: (requestedMimeType) {
        final recorder = MediaRecorder(
          recordingStream,
          {'mimeType': requestedMimeType},
        );
        void onData(Event event) {
          final chunk = (event as BlobEvent).data;
          if (chunk == null) {
            return;
          }
          if (chunk.size > 0) {
            _recordedChunks.add(chunk);
          }
          // The browser may refine a generic MIME type after recording starts.
          if (chunk.type.isNotEmpty) {
            mimeType = chunk.type;
          }
        }

        recorder.addEventListener('dataavailable', onData);
        try {
          recorder.start();
        } catch (e) {
          recorder.removeEventListener('dataavailable', onData);
          if (recorder.state != 'inactive') {
            recorder.stop();
          }
          rethrow;
        }
        final actualMimeType = recorder.mimeType;
        mimeType = actualMimeType != null && actualMimeType.isNotEmpty
            ? actualMimeType
            : requestedMimeType;
        return recorder;
      },
    );
  }

  @override
  Future<String> get stopRecordScreen {
    final completer = _stopCompleter;
    final recorder = mediaRecorder;
    if (completer == null) {
      return Future<String>.value('');
    }
    if (recorder != null && recorder.state != 'inactive') {
      try {
        recorder.stop();
      } catch (e) {
        _recordingFailed = true;
        print('Unable to stop screen recording: $e');
        _finishRecording(recorder);
      }
    }
    return completer.future;
  }

  void _finishRecording(MediaRecorder recorder) {
    final completer = _stopCompleter;
    if (!identical(mediaRecorder, recorder) ||
        completer == null ||
        completer.isCompleted) {
      return;
    }

    try {
      if (_recordingFailed || _recordedChunks.isEmpty) {
        completer.complete('');
        return;
      }
      final actualMimeType = mimeType ?? recorder.mimeType ?? '';
      final fileName = recordingFileName(name!, actualMimeType);
      final blob = Blob(_recordedChunks, actualMimeType);
      final url = Url.createObjectUrl(blob);
      final anchor = AnchorElement(href: url)
        ..style.display = 'none'
        ..download = fileName;
      try {
        document.body!.append(anchor);
        anchor.click();
      } finally {
        anchor.remove();
        // Let the browser consume the download URL before revoking it.
        Timer(const Duration(seconds: 1), () => Url.revokeObjectUrl(url));
      }
      name = fileName;
      completer.complete(fileName);
    } catch (e) {
      print('Unable to download screen recording: $e');
      completer.complete('');
    } finally {
      _releaseStreams();
      mediaRecorder = null;
      _recordedChunks.clear();
    }
  }

  void _releaseStreams() {
    stream?.getTracks().forEach((track) => track.stop());
    _audioStream?.getTracks().forEach((track) => track.stop());
    stream = null;
    _audioStream = null;
  }
}
