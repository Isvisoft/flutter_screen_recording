import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screen_recording_web/src/recording_format.dart';

void main() {
  group('recording formats', () {
    test('prefers H.264 MP4 without an audio codec for video-only streams', () {
      expect(
        recordingMimeTypes(hasAudio: false).first,
        'video/mp4;codecs=avc1',
      );
      expect(
        recordingMimeTypes(hasAudio: false)
            .any((type) => type.contains('opus') || type.contains('mp4a')),
        isFalse,
      );
    });

    test('prefers H.264 and AAC when the stream contains audio', () {
      expect(
        recordingMimeTypes(hasAudio: true).first,
        'video/mp4;codecs=avc1,mp4a.40.2',
      );
      expect(
        recordingMimeTypes(hasAudio: true),
        containsAllInOrder(<String>[
          'video/mp4',
          'video/webm;codecs=vp9,opus',
          'video/webm;codecs=vp8,opus',
          'video/webm',
        ]),
      );
    });

    for (final hasAudio in <bool>[false, true]) {
      test('passes only the exact supported MIME string (audio=$hasAudio)', () {
        final checked = <String>[];
        final started = <String>[];
        final result = createRecorderForSupportedFormat<String>(
          hasAudio: hasAudio,
          isTypeSupported: (type) {
            checked.add(type);
            return true;
          },
          createAndStart: (type) {
            started.add(type);
            return type;
          },
        );
        expect(checked, <String>[recordingMimeTypes(hasAudio: hasAudio).first]);
        expect(started, checked);
        expect(result, checked.single);
      });

      test('falls back to WebM if MP4 is unsupported (audio=$hasAudio)', () {
        final result = createRecorderForSupportedFormat<String>(
          hasAudio: hasAudio,
          isTypeSupported: (type) => type.startsWith('video/webm'),
          createAndStart: (type) => type,
        );
        expect(
          result,
          hasAudio ? 'video/webm;codecs=vp9,opus' : 'video/webm;codecs=vp9',
        );
      });
    }

    test('accepts a browser supporting only generic MP4', () {
      expect(
        createRecorderForSupportedFormat<String>(
          hasAudio: true,
          isTypeSupported: (type) => type == 'video/mp4',
          createAndStart: (type) => type,
        ),
        'video/mp4',
      );
    });

    test('does not accept video-only support for an audio configuration', () {
      final checked = <String>[];
      expect(
        createRecorderForSupportedFormat<String>(
          hasAudio: true,
          isTypeSupported: (type) {
            checked.add(type);
            return type == 'video/mp4;codecs=avc1' ||
                type == 'video/webm;codecs=vp8,opus';
          },
          createAndStart: (type) => type,
        ),
        'video/webm;codecs=vp8,opus',
      );
      expect(checked, isNot(contains('video/mp4;codecs=avc1')));
    });

    test('tries the next format if construction or synchronous start fails', () {
      final attempted = <String>[];
      final result = createRecorderForSupportedFormat<String>(
        hasAudio: false,
        isTypeSupported: (_) => true,
        createAndStart: (type) {
          attempted.add(type);
          if (type.startsWith('video/mp4')) {
            throw StateError('Encoder unavailable');
          }
          return type;
        },
      );
      expect(result, 'video/webm;codecs=vp9');
      expect(attempted, <String>[
        'video/mp4;codecs=avc1',
        'video/mp4',
        'video/webm;codecs=vp9',
      ]);
    });

    test('falls back to generic WebM when explicit codecs are unsupported', () {
      expect(
        createRecorderForSupportedFormat<String>(
          hasAudio: false,
          isTypeSupported: (type) => type == 'video/webm',
          createAndStart: (type) => type,
        ),
        'video/webm',
      );
    });

    test('does not construct a recorder if no candidate is supported', () {
      expect(
        () => createRecorderForSupportedFormat<String>(
          hasAudio: false,
          isTypeSupported: (_) => false,
          createAndStart: (_) {
            fail('An unsupported MIME type must not be used');
          },
        ),
        throwsUnsupportedError,
      );
    });

    test('reports failure when all supported candidates fail to start', () {
      expect(
        () => createRecorderForSupportedFormat<String>(
          hasAudio: true,
          isTypeSupported: (_) => true,
          createAndStart: (_) => throw StateError('Encoder unavailable'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('download filenames', () {
    final cases = <List<String>>[
      <String>['session', 'video/mp4', 'session.mp4'],
      <String>['session', 'video/webm', 'session.webm'],
      <String>['session.webm', 'video/mp4;codecs=avc1', 'session.mp4'],
      <String>['session.mp4', 'video/webm;codecs=vp8,opus', 'session.webm'],
      <String>['session.mp4', 'video/mp4', 'session.mp4'],
      <String>['session.WEBM', 'video/mp4', 'session.mp4'],
      <String>['session.MP4', 'video/webm', 'session.webm'],
      <String>['session.v2', 'video/mp4', 'session.v2.mp4'],
      <String>['session.v2.webm', 'video/mp4', 'session.v2.mp4'],
      <String>[' session ', ' VIDEO/MP4 ;codecs=avc1', 'session.mp4'],
      <String>['', 'video/mp4', 'recording.mp4'],
      <String>['.mp4', 'video/webm', 'recording.webm'],
    ];
    for (final values in cases) {
      test('${values[0]} / ${values[1]} -> ${values[2]}', () {
        expect(recordingFileName(values[0], values[1]), values[2]);
      });
    }

    test('does not label an unknown container as MP4', () {
      expect(
        () => recordingFileName('session.mp4', 'video/unknown'),
        throwsUnsupportedError,
      );
    });
  });
}
