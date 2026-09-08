# flutter_screen_recording

The web implementation of [`flutter_screen_recording`][1].

## Usage

This package is [endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin),
which means you can simply use `flutter_screen_recording` normally. This package will be automatically included in your app when you do.

## Recording format

Web recordings prefer native MP4, with WebM as a fallback. No conversion,
FFmpeg dependency, or server upload is involved. The public start/stop API is
unchanged.

The plugin checks each complete MIME type with `MediaRecorder.isTypeSupported`,
then attempts to construct and start the recorder in this order:

1. MP4 with H.264 (`avc1`) and, for streams containing audio, AAC (`mp4a.40.2`).
2. Generic MP4, allowing the browser to select its supported codecs.
3. WebM with VP9, then VP8, with Opus only when the stream contains audio.
4. Generic WebM.

If construction or synchronous start fails, the next supported candidate is
tried. Later asynchronous recorder errors fail that recording; an in-progress
recording is not silently restarted in another format.

Availability depends on the browser, operating system, and installed encoders.
MP4 is a container: the generic MP4 fallback does not guarantee H.264/AAC or
playback in every external player. A `.mp4` filename does not force MP4 encoding.
Always delivering MP4 on a browser that cannot record it would require a separate
conversion step, which this package does not provide.

The downloaded filename and the value returned by `stopRecordScreen` use the
actual recorded container. For example, a requested `session.mp4` becomes
`session.webm` when WebM is used, and a requested `session.webm` becomes
`session.mp4` when MP4 is used. Names without an extension receive one. Other
suffixes, such as `session.v2`, are preserved before the recording extension.
On web, the returned string is a download filename, not a local filesystem path.
A failed or empty recording returns an empty string and is not downloaded.

## Tests

Run the format-selection and filename regression tests from this directory:

```sh
flutter pub get
flutter test
```

Before release, also verify real screen captures with and without microphone
audio in Chrome/Edge, Firefox, and Safari, including stopping from the browser's
sharing controls. Check the downloaded file's container and playback, not only
its extension. When testing the main package from a checkout, override its
`flutter_screen_recording_web` dependency to this local package so the app does
not use the previously published web implementation.

[1]: ../flutter_screen_recording
