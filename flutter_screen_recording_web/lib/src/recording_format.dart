/// Recording formats in preference order. Probe the complete MIME string,
/// including the audio codec only when the stream actually contains audio.
List<String> recordingMimeTypes({required bool hasAudio}) {
  return <String>[
    hasAudio
        ? 'video/mp4;codecs=avc1,mp4a.40.2'
        : 'video/mp4;codecs=avc1',
    'video/mp4',
    hasAudio ? 'video/webm;codecs=vp9,opus' : 'video/webm;codecs=vp9',
    hasAudio ? 'video/webm;codecs=vp8,opus' : 'video/webm;codecs=vp8',
    'video/webm',
  ];
}

/// Creates and synchronously starts a recorder using an advertised format.
/// A supported MIME type can still fail during construction or start, so try
/// the remaining candidates before reporting failure. Asynchronous recording
/// errors must be handled by the caller's MediaRecorder event listeners.
T createRecorderForSupportedFormat<T>({
  required bool hasAudio,
  required bool Function(String) isTypeSupported,
  required T Function(String) createAndStart,
}) {
  Object? lastError;
  for (final mimeType in recordingMimeTypes(hasAudio: hasAudio)) {
    if (!isTypeSupported(mimeType)) {
      continue;
    }
    try {
      // Pass exactly the MIME string that was checked, without adding codecs.
      return createAndStart(mimeType);
    } catch (error) {
      lastError = error;
    }
  }
  throw UnsupportedError(
    lastError == null
        ? 'This browser cannot record MP4 or WebM.'
        : 'No supported recording format could be started: $lastError',
  );
}

/// Names the download after its actual container, not the requested extension.
String recordingFileName(String requestedName, String mimeType) {
  final container = mimeType.split(';').first.trim().toLowerCase();
  final String extension;
  if (container == 'video/mp4') {
    extension = 'mp4';
  } else if (container == 'video/webm') {
    extension = 'webm';
  } else {
    throw UnsupportedError('Unsupported recording MIME type: $mimeType');
  }

  final baseName = requestedName.trim().replaceFirst(
        RegExp(r'\.(mp4|webm)$', caseSensitive: false),
        '',
      );
  return '${baseName.isEmpty ? 'recording' : baseName}.$extension';
}
