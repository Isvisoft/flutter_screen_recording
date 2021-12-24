import 'dart:async';
import 'dart:developer';
import 'dart:html';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

mixin RecordScreenMixin {
  //Userid, object
  final participantsAudioTracks = <String, MediaStream>{};

  //Userid, mediaStreamAudioSourceNodeId
  final participantsAudioSourceNodeIds = <String, String>{};

  final recordingStatusStreamController = StreamController<bool>.broadcast()
    ..add(false);
  final recordPauseStatusStreamController = StreamController<bool>.broadcast()
    ..add(false);

  bool recordingScreen = false;

  void startRecordScreen(String fileName) async {
    final result = await FlutterScreenRecording.startRecordScreenAndAudio(
      fileName,
      recordSystemAudio: true,
      disableUserAudio: true,
      onStop: onStopRecording,
    );
    recordingScreen = result;
    recordingStatusStreamController.add(result);
    addCurrentAudioTracksToRecordScreenStream();
  }

  void pauseRecordScreen() {
    final pauseStatus = FlutterScreenRecording.pauseRecordScreen();
    recordPauseStatusStreamController.add(pauseStatus);
  }

  void resumeRecordScreen() {
    final pauseStatus = !FlutterScreenRecording.resumeRecordScreen();
    recordPauseStatusStreamController.add(pauseStatus);
  }

  void stopRecordScreen() {
    FlutterScreenRecording.stopRecordScreen;
  }

  void onStopRecording(String fileName) {
    recordingScreen = false;
    recordingStatusStreamController.add(false);
    participantsAudioSourceNodeIds.clear();
  }

  void storeAudioTrackReference(String uid, dynamic audioStream) {
    try {
      final audioStreamDart = audioStream as MediaStream;

      participantsAudioTracks[uid] = audioStreamDart;
    } catch (error, stackTrace) {
      log(
        "Error storeAudioTrackReference",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void removeAudioTrackReference(String uid) {
    participantsAudioTracks.remove(uid);
  }

  void addAudioTrackToScreenRecord(String uid, dynamic audioStream) {
    try {
      final audioStreamDart = audioStream as MediaStream;
      final result = FlutterScreenRecording.addAudioTrack(audioStreamDart);

      participantsAudioSourceNodeIds[uid] = result;
    } catch (error, stackTrace) {
      log(
        "Error addAudioTrackToScreenRecord",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void removeAudioTrackFromScreenRecord(dynamic uid) {
    final mediaStreamAudioSourceNodeId = participantsAudioSourceNodeIds[uid];
    if (mediaStreamAudioSourceNodeId != null) {
      FlutterScreenRecording.removeAudioTrack(mediaStreamAudioSourceNodeId);
    }
    participantsAudioSourceNodeIds.remove(uid);
  }

  void addCurrentAudioTracksToRecordScreenStream() {
    for (final uid in participantsAudioTracks.keys) {
      final audioStream = participantsAudioTracks[uid];
      if (audioStream != null) {
        final result = FlutterScreenRecording.addAudioTrack(audioStream);

        participantsAudioSourceNodeIds[uid] = result;
      }
    }
  }

  void onDisposeScreenRecord() {
    recordingScreen = false;
    participantsAudioTracks.clear();
    participantsAudioSourceNodeIds.clear();
    recordingStatusStreamController.close();
    recordPauseStatusStreamController.close();
  }
}
