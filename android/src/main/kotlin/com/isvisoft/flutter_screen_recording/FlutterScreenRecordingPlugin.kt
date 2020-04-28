
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
        PluginRegistry.ActivityResultListener{

    var mScreenDensity: Int = 0
    var mMediaRecorder: MediaRecorder? = null
    var mProjectionManager: MediaProjectionManager? = null
    var mMediaProjection : MediaProjection?= null
    var mMediaProjectionCallback : MediaProjectionCallback? = null
    var mVirtualDisplay: VirtualDisplay? = null
    var mDisplayWidth: Int = 1280
    var mDisplayHeight: Int = 800
    var storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath + File.separator
    var videoName: String = ""
    private val SCREEN_RECORD_REQUEST_CODE = 333
    private val SCREEN_STOP_RECORD_REQUEST_CODE = 334

    private lateinit var _result: MethodChannel.Result



    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_screen_recording")
            val plugin = FlutterScreenRecordingPlugin(registrar)
            channel.setMethodCallHandler(plugin)
            registrar.addActivityResultListener(plugin)
        }
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {

        if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                mMediaProjectionCallback = MediaProjectionCallback()
                mMediaProjection = mProjectionManager?.getMediaProjection(resultCode, data)
                mMediaProjection?.registerCallback(mMediaProjectionCallback, null)
                mVirtualDisplay = createVirtualDisplay()
                _result.success(true)
                mMediaRecorder?.start()
                return true
            }else{
            _result.success(false)
            }
        }
        
        return false
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "startRecordScreen") {
            try{
                _result = result
                mMediaRecorder = MediaRecorder()
                mProjectionManager = registrar.context().applicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?
                var metrics: DisplayMetrics = DisplayMetrics()
                var windowManager = registrar.context().applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager.defaultDisplay.getMetrics(metrics)
                mScreenDensity = metrics.densityDpi
                mDisplayWidth = metrics.widthPixels
                mDisplayHeight = metrics.heightPixels
                videoName = call.arguments.toString()
                startRecordScreen()
                //result.success(true)
            }catch(e: Exception){
                result.success(false)
            }

        } else if (call.method == "stopRecordScreen") {
            try{
                if(mMediaRecorder != null){
                    stopRecordScreen()
                    result.success("${storePath}${videoName}.mp4")
                }else{
                    result.success("")
                }
            }catch(e: Exception){
                result.success("")
            }

        } else if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }


    fun startRecordScreen() {
        initRecorder()
        val permissionIntent = mProjectionManager?.createScreenCaptureIntent()
        ActivityCompat.startActivityForResult(registrar.activity(), permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)
    }

    fun stopRecordScreen() {
            mMediaRecorder?.stop()
            mMediaRecorder?.reset()
            stopScreenSharing()
            Log.d("STOP RECORD",    "starting")

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
            mMediaRecorder?.setOutputFile("${storePath}${videoName}.mp4")
            mMediaRecorder?.setVideoSize(mDisplayWidth, mDisplayHeight)
            mMediaRecorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            mMediaRecorder?.setVideoEncodingBitRate(5 * mDisplayWidth * mDisplayHeight)
            mMediaRecorder?.setVideoFrameRate(30)
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