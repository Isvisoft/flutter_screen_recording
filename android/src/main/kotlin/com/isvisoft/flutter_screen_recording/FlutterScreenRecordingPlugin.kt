package com.isvisoft.flutter_screen_recording

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Environment
import androidx.core.app.ActivityCompat
import android.util.Log
import com.hbisoft.hbrecorder.HBRecorder
import com.hbisoft.hbrecorder.HBRecorderListener
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.util.*


class FlutterScreenRecordingPlugin(
        private val registrar: Registrar
) : MethodCallHandler, PluginRegistry.ActivityResultListener, HBRecorderListener {


    var hbRecorder: HBRecorder? = null
    //    val storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).absolutePath + File.separator + "calisto"
    val storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath + File.separator + "calisto"
    val SCREEN_RECORD_REQUEST_CODE = 333;
    val SCREEN_STOP_RECORD_REQUEST_CODE = 334;

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_screen_recording")
            channel.setMethodCallHandler(FlutterScreenRecordingPlugin(registrar))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK) {

            if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
                //It is important to call this before starting the recording
                hbRecorder?.onActivityResult(resultCode, data, (registrar.context() as FlutterApplication).currentActivity);
                //Start screen recording
                val pathRecord = "${storePath}/${Date().time}.mp4";

                hbRecorder?.setOutputPath(pathRecord)
                hbRecorder?.startScreenRecording(data)

            }
        } else if (requestCode == SCREEN_STOP_RECORD_REQUEST_CODE) {
            hbRecorder?.stopScreenRecording()
        }
        return true;
    }

    override fun HBRecorderOnComplete() {
        Log.d("88888", "Finish")
    }


    override fun onMethodCall(call: MethodCall, result: Result) {

        print(call.method)
        if (call.method == "startRecordScreen") {

            hbRecorder = HBRecorder(registrar.context(), this)

            if (ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
                    ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions((registrar.context() as FlutterApplication).currentActivity,
                        Array<String>(1) { Manifest.permission.RECORD_AUDIO; Manifest.permission.WRITE_EXTERNAL_STORAGE; Manifest.permission.READ_EXTERNAL_STORAGE },
                        0)

            }
            startRecordScreen()
        } else if (call.method == "stopRecordScreen") {
            stopRecordScreen()
        } else if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    fun startRecordScreen() {
        val mediaProjectionManager = registrar.context().applicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?
        val permissionIntent = mediaProjectionManager?.createScreenCaptureIntent()
        Log.d("aaaaa", (registrar.context() as FlutterApplication).currentActivity.toString())
        ActivityCompat.startActivityForResult((registrar.context().applicationContext as FlutterApplication).currentActivity, permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)
//        ActivityCompat.startActivityForResult((registrar.context().applicationContext as FlutterApplication).currentActivity, Intent(), SCREEN_STOP_RECORD_REQUEST_CODE, null);

    }

    fun stopRecordScreen() {

        val mediaProjectionManager = registrar.context().getApplicationContext().getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?
        val permissionIntent = mediaProjectionManager?.createScreenCaptureIntent()
        Log.d("ssss", (registrar.context() as FlutterApplication).currentActivity.toString())
        ActivityCompat.startActivityForResult((registrar.context().applicationContext as FlutterApplication).currentActivity, permissionIntent!!, SCREEN_STOP_RECORD_REQUEST_CODE, null);
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
