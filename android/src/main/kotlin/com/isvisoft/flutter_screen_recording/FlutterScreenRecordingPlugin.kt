
package com.isvisoft.flutter_screen_recording

import android.Manifest
import kotlin.concurrent.schedule
import java.util.*
import java.io.IOException
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjection
import android.hardware.display.VirtualDisplay
import android.hardware.display.DisplayManager
import android.view.WindowManager
import android.media.projection.MediaProjectionManager
import android.util.DisplayMetrics
import android.os.Environment
import androidx.core.app.ActivityCompat
import android.media.MediaRecorder
import android.graphics.Point
import android.util.Log
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.lang.Math


class FlutterScreenRecordingPlugin(
        private val registrar: Registrar
) : MethodCallHandler,
        PluginRegistry.ActivityResultListener,
        PluginRegistry.RequestPermissionsResultListener{

    var mScreenDensity: Int = 0
    var mMediaRecorder: MediaRecorder? = null
    var mProjectionManager: MediaProjectionManager? = null
    var mMediaProjection : MediaProjection?= null
    var mMediaProjectionCallback : MediaProjectionCallback? = null
    var mVirtualDisplay: VirtualDisplay? = null
    var mDisplayWidth: Int = 1280
    var mDisplayHeight: Int = 800
    val storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath + File.separator + "prueba.mp4"

    private val SCREEN_RECORD_REQUEST_CODE = 333
    private val SCREEN_STOP_RECORD_REQUEST_CODE = 334



    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_screen_recording")
            val plugin = FlutterScreenRecordingPlugin(registrar)
            channel.setMethodCallHandler(plugin)
            registrar.addActivityResultListener(plugin)
            registrar.addRequestPermissionsResultListener(plugin)
        }
    }


    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        if(grantResults.indexOf(PackageManager.PERMISSION_DENIED) < 0){
            Timer().schedule(2000) {
                Log.d("DFA",    "dfa")
                startRecordScreen()
            }
            return true
        }

        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {

                mMediaProjectionCallback = MediaProjectionCallback()
                mMediaProjection = mProjectionManager?.getMediaProjection(resultCode, data)
                mMediaProjection?.registerCallback(mMediaProjectionCallback, null)
                mVirtualDisplay = createVirtualDisplay()
                mMediaRecorder?.start()
                Log.d("START RECORD",    "starting")

            }
        } else if (requestCode == SCREEN_STOP_RECORD_REQUEST_CODE) {
            mMediaRecorder?.stop()
            mMediaRecorder?.reset()
            stopScreenSharing()
            Log.d("STOP RECORD",    "starting")

        }
        return true
    }



    override fun onMethodCall(call: MethodCall, result: Result) {

        if (call.method == "startRecordScreen") {

            mMediaRecorder = MediaRecorder()
            mProjectionManager = registrar.context().applicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?
            var metrics: DisplayMetrics = DisplayMetrics()
            var windowManager = registrar.context().applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            windowManager.defaultDisplay.getMetrics(metrics)
            mScreenDensity = metrics.densityDpi
            mDisplayWidth = Math.round(metrics.widthPixels / metrics.scaledDensity)
            mDisplayHeight = Math.round(metrics.heightPixels / metrics.scaledDensity)


            if (
                    ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
                    ActivityCompat.checkSelfPermission(registrar.context(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED)
            {

                ActivityCompat.requestPermissions((registrar.context() as FlutterApplication).currentActivity,
                        arrayOf(
                                Manifest.permission.RECORD_AUDIO,
                                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                                Manifest.permission.READ_EXTERNAL_STORAGE),1)

            }else{
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




    fun startRecordScreen() {
        initRecorder()
        val permissionIntent = mProjectionManager?.createScreenCaptureIntent()
        ActivityCompat.startActivityForResult((registrar.context().applicationContext as FlutterApplication).currentActivity, permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)
    }

    fun stopRecordScreen() {
        val permissionIntent = mProjectionManager?.createScreenCaptureIntent()
        ActivityCompat.startActivityForResult((registrar.context().applicationContext as FlutterApplication).currentActivity, permissionIntent!!, SCREEN_STOP_RECORD_REQUEST_CODE, null)
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

    private fun createVirtualDisplay() : VirtualDisplay?{
        return mMediaProjection?.createVirtualDisplay("MainActivity", mDisplayWidth, mDisplayHeight, mScreenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, mMediaRecorder?.getSurface(), null, null)
    }

    private fun initRecorder(){
        try{
            mMediaRecorder?.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            mMediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mMediaRecorder?.setOutputFile(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath + File.separator + "video.mp4")
            mMediaRecorder?.setVideoSize(mDisplayWidth, mDisplayHeight)
            mMediaRecorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            mMediaRecorder?.setVideoEncodingBitRate(5 * mDisplayWidth * mDisplayHeight)
            mMediaRecorder?.setVideoFrameRate(60) // 30
            mMediaRecorder?.prepare()
        }catch(e : IOException){
            Log.d("--INIT-RECORDER", e.message)
        }
    }

    private fun destroyMediaProjection() {
        if (mMediaProjection != null) {
            mMediaProjection?.unregisterCallback(mMediaProjectionCallback)
            mMediaProjection?.stop()
            mMediaProjection = null
        }
        Log.d("TAG", "MediaProjection Stopped")
    }

    private fun stopScreenSharing(){
        if(mVirtualDisplay != null){
            mVirtualDisplay?.release()
            destroyMediaProjection()
        }
    }

    inner class MediaProjectionCallback : MediaProjection.Callback() {
        override fun onStop() {
            mMediaRecorder?.stop()
            mMediaRecorder?.reset()

            mMediaProjection = null
            stopScreenSharing()
        }
    }

}