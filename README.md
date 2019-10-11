# flutter_screen_recording

A new Flutter plugin for record the screen.

## Getting Started

This plugin can be used for record the screen on android and iOS devices.

1) For start the recording

```dart
FlutterScreenRecording.startRecordScreen;
```
2) For stop the recording

```dart
FlutterScreenRecording.stopRecordScreen;
```

## Android

We use the library [HBRecorder](https://github.com/HBiSoft/HBRecorder) for record the screen in android you need to install the lib in your android app.
**Adding the library to your project:**
---
Add the following in your root build.gradle at the end of repositories:

```java
allprojects {
    repositories {
        ...
        maven { url 'https://jitpack.io' }	    
    }
}
```
    
Implement library in your app level build.gradle:

```java
dependencies {
    implementation 'com.github.HBiSoft:HBRecorder:0.1.4'
}
```
    
Add the following permissions in your manifest:
```java
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_INTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```
</br>    
That's it `HBRecorder` is now ready to be used.

## iOS

You only need add the permission message 
