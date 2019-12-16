package com.isvisoft.flutter_screen_recording

import android.Manifest
import kotlin.concurrent.schedule
import java.util.*

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


class FlutterScreenRecordingPlugin(
    private val registrar: Registrar
) : MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener ,
    HBRecorderListener {


    private lateinit var stopResult: Result
    private lateinit var startResult: Result
    var hbRecorder: HBRecorder? = null
    val storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath

    private val SCREEN_RECORD_REQUEST_CODE = 333;
    private val SCREEN_STOP_RECORD_REQUEST_CODE = 334;



    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_screen_recording")
            val plugin = FlutterScreenRecordingPlugin(registrar)
            channel.setMethodCallHandler(plugin)
            registrar.addActivityResultListener(plugin);
            registrar.addRequestPermissionsResultListener(plugin);
        }
    }


    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        if(grantResults.indexOf(PackageManager.PERMISSION_DENIED) < 0){
            Timer().schedule(500) {
                startRecordScreen()
            }
            return true
        }

        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                //It is important to call this before starting the recording

                //Start screen recording
                hbRecorder?.setOutputPath(storePath)
                hbRecorder?.isAudioEnabled(false)
                hbRecorder?.recordHDVideo(false)
                hbRecorder?.startScreenRecording(data, resultCode, registrar.activity())
                startResult.success(null)
            }
        } else if (requestCode == SCREEN_STOP_RECORD_REQUEST_CODE) {
            hbRecorder?.stopScreenRecording()
            stopResult.success(null)
        }
        return true;
    }

    override fun HBRecorderOnError(errorCode: Int) {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun HBRecorderOnComplete() {
        Log.d("--RECORDING FINISH", "finish")
    }


    override fun onMethodCall(call: MethodCall, result: Result) {

        if (call.method == "startRecordScreen") {

            startResult = result
            hbRecorder = HBRecorder(registrar.context(), this)

            if (
                ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED)
            {

                ActivityCompat.requestPermissions((registrar.context() as FlutterApplication).currentActivity,
                    arrayOf(
                        Manifest.permission.RECORD_AUDIO,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
                        Manifest.permission.READ_EXTERNAL_STORAGE),1)

            } else{
                startRecordScreen()
            }

        } else if (call.method == "stopRecordScreen") {
            stopResult = result
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
        ActivityCompat.startActivityForResult((registrar.context().applicationContext as FlutterApplication).currentActivity, permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)

    }

    fun stopRecordScreen() {
        hbRecorder?.stopScreenRecording()
        stopResult.success(hbRecorder?.filePath)
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
