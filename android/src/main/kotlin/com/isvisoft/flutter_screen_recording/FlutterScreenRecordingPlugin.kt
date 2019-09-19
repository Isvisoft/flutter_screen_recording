package com.isvisoft.flutter_screen_recording

import android.Manifest
import android.content.pm.PackageManager
import android.media.CamcorderProfile
import android.media.MediaRecorder
import android.os.Environment
import android.support.v4.app.ActivityCompat
import android.util.Log
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.util.*


class FlutterScreenRecordingPlugin : MethodCallHandler {

    private val registrar: Registrar

    var recorder: MediaRecorder? = null
    //    val storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).absolutePath + File.separator + "calisto"
    val storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath + File.separator + "calisto"

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_screen_recording")
            channel.setMethodCallHandler(FlutterScreenRecordingPlugin(registrar))
        }
    }

    constructor(registrar: Registrar) {
        this.registrar = registrar;
    }

    override fun onMethodCall(call: MethodCall, result: Result) {

        print(call.method)
        if (call.method == "startRecordScreen") {

            Log.d("TAAAAG", ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.WRITE_EXTERNAL_STORAGE).toString())
            if (ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
                    ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions((registrar.context() as FlutterApplication).currentActivity,
                        Array<String>(1) { Manifest.permission.RECORD_AUDIO; Manifest.permission.WRITE_EXTERNAL_STORAGE; Manifest.permission.READ_EXTERNAL_STORAGE },
                        0);

            } else {
                startRecordScreen()
            }
        } else if (call.method == "stopRecordScreen") {
            stopRecordScreen()
        } else if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    fun startRecordScreen(): String {
        recorder = MediaRecorder();
//        recorder?.setAudioSource(MediaRecorder.AudioSource.MIC);

        recorder?.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder?.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);

//        recorder?.setVideoSize(640, 480);
//        recorder?.setVideoFrameRate(16);
//        recorder?.setVideoEncodingBitRate(2000000);

//        recorder?.setAudioEncoder(MediaRecorder.AudioEncoder.DEFAULT);
        recorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264);

//        recorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
//        val profile: CamcorderProfile = CamcorderProfile.get(CamcorderProfile.QUALITY_HIGH)
//        recorder?.setProfile(profile)

//        Log.d("QQQQQQ", path)
//        val storePath = Environment.getExternalStorageDirectory().absolutePath + File.separator + "calisto"

//        Log.d("QQQQQQ", registrar.context().getFilesDir().getPath().toString())
//        val pathRecord = "${registrar.context().getFilesDir().getPath()}/${Date().time}.mp4";
        generateFile()
        val pathRecord = "${storePath}/${Date().time}.mp4";
        Log.d("QQQQQQ", pathRecord)

//        File(path).createNewFile()
//        File(pathRecord).createNewFile()
        recorder?.setOutputFile(pathRecord);
        recorder?.prepare();
        recorder?.start();   // Recording is now started
        return pathRecord
    }

    fun stopRecordScreen() {

        Log.d("QQQQQQ", "stopRecordScreen")

        if (recorder != null) {
            Log.d("QQQQQQ", "stopRecordScre2334234234en")

            recorder?.stop();
            recorder?.reset();   // You can reuse the object by going back to setAudioSource() step
            recorder?.release(); // Now the object cannot be reused
        }
    }

    private fun generateFile(extension: String = ""): File {
        val appDir = File(storePath)
        if (!appDir.exists()) {
            appDir.mkdir()
        }
        var fileName = System.currentTimeMillis().toString()
        if (extension.isNotEmpty()) {
            fileName += (".$extension")
        }
        return File(appDir, fileName)
    }
}
