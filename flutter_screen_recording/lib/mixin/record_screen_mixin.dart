import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

mixin RecordScreenMixin {
  //Userid, object
  final participantsAudioTracks = <String, MediaStream>{};

  //Userid, mediaStreamAudioSourceNodeId
  final participantsAudioSourceNodeIds = <String, String>{};

  final recordingStatusStreamController = StreamController<bool>()..add(false);
  final recordPauseStatusStreamController = StreamController<bool>()
    ..add(false);

  Stream<bool> recordingStatusStream;
  Stream<bool> recordPauseStatusStream;

  bool recordingScreen = false;

  void onInitScreenRecord() {
    recordingStatusStream =
        recordingStatusStreamController.stream.asBroadcastStream();
    recordPauseStatusStream =
        recordPauseStatusStreamController.stream.asBroadcastStream();
  }

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

  void onStopRecording(result) {
    recordingScreen = false;
    recordingStatusStreamController.add(false);
    participantsAudioSourceNodeIds.clear();
  }

  void storeAudioTrackReference(String uid, dynamic audioStream) {
    participantsAudioTracks[uid] = audioStream as MediaStream;
  }

  void removeAudioTrackReference(String uid) {
    participantsAudioTracks.remove(uid);
  }

  void addAudioTrackToScreenRecord(String uid, dynamic audioStream) {
    final result =
        FlutterScreenRecording.addAudioTrack(audioStream as MediaStream);

    participantsAudioSourceNodeIds[uid] = result;
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

  Widget buildRecordingPauseStatusContainer(
    BuildContext context,
    Widget Function(BuildContext context, bool paused) builder,
  ) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: recordPauseStatusStream,
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      },
    );
  }

  Widget buildRecordingStatusContainer(
    BuildContext context,
    Widget Function(BuildContext context, bool recording) builder,
  ) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: recordingStatusStream,
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      },
    );
  }
}
