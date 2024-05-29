package com.isvisoft.flutter_screen_recording

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException

import com.foregroundservice.ForegroundService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding


class FlutterScreenRecordingPlugin() : MethodCallHandler, PluginRegistry.ActivityResultListener, FlutterPlugin, ActivityAware {

    var mScreenDensity: Int = 0
    var mMediaRecorder: MediaRecorder? = null
    var mProjectionManager: MediaProjectionManager? = null
    var mMediaProjection: MediaProjection? = null
    var mMediaProjectionCallback: MediaProjectionCallback? = null
    var mVirtualDisplay: VirtualDisplay? = null
    var mDisplayWidth: Int = 1280
    var mDisplayHeight: Int = 800
    var videoName: String? = ""
    var mFileName: String? = ""
    var recordAudio: Boolean? = false;
    private val SCREEN_RECORD_REQUEST_CODE = 333

    private lateinit var _result: MethodChannel.Result

    var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    var activityBinding: ActivityPluginBinding? = null;


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                mMediaProjectionCallback = MediaProjectionCallback()
                mMediaProjection = mProjectionManager?.getMediaProjection(resultCode, data!!)
                mMediaProjection?.registerCallback(mMediaProjectionCallback!!, null)
                mVirtualDisplay = createVirtualDisplay()
                _result.success(true)
                return true
            } else {
                _result.success(false)
            }
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val appContext = pluginBinding!!.applicationContext

        when (call.method) {
            "startRecordScreen" -> {
                try {
                    _result = result
                    var title = call.argument<String?>("title")
                    var message = call.argument<String?>("message")
                    if (title == null || title == "") {
                        title = "Your screen is being recorded";
                    }
                    if (message == null || message == "") {
                        message = "Your screen is being recorded"
                    }
                    ForegroundService.startService(appContext, title, message)
                    mProjectionManager =
                        appContext.getSystemService(
                            Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?

                    val metrics = DisplayMetrics()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        mMediaRecorder = MediaRecorder(appContext)
                    } else {
                        @Suppress("DEPRECATION")
                        mMediaRecorder = MediaRecorder()
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val display = activityBinding!!.activity.display
                        display?.getRealMetrics(metrics)
                    } else {
                        val defaultDisplay = appContext.getDisplay()
                        defaultDisplay?.getMetrics(metrics)
                    }
                    mScreenDensity = metrics.densityDpi
                    calculeResolution(metrics)
                    videoName = call.argument<String?>("name")
                    recordAudio = call.argument<Boolean?>("audio")
                    startRecordScreen()

                } catch (e: Exception) {
                    println("Error onMethodCall startRecordScreen")
                    println(e.message)
                    result.success(false)
                }
            }
            "stopRecordScreen" -> {
                try {
                    ForegroundService.stopService(appContext)
                    if (mMediaRecorder != null) {
                        stopRecordScreen()
                        result.success(mFileName)
                    } else {
                        result.success("")
                    }
                } catch (e: Exception) {
                    result.success("")
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun calculeResolution(metrics: DisplayMetrics) {

        mDisplayHeight = metrics.heightPixels
        mDisplayWidth = metrics.widthPixels

        var maxRes = 1280.0;
        if (metrics.scaledDensity >= 3.0f) {
            maxRes = 1920.0;
        }
        if (metrics.widthPixels > metrics.heightPixels) {
            var rate = metrics.widthPixels / maxRes

            if (rate > 1.5) {
                rate = 1.5
            }
            mDisplayWidth = maxRes.toInt()
            mDisplayHeight = (metrics.heightPixels / rate).toInt()
            println("Rate : $rate")
        } else {
            var rate = metrics.heightPixels / maxRes
            if (rate > 1.5) {
                rate = 1.5
            }
            mDisplayHeight = maxRes.toInt()
            mDisplayWidth = (metrics.widthPixels / rate).toInt()
            println("Rate : $rate")
        }

        println("Scaled Density")
        println(metrics.scaledDensity)
        println("Original Resolution ")
        println(metrics.widthPixels.toString() + " x " + metrics.heightPixels)
        println("Calcule Resolution ")
        println("$mDisplayWidth x $mDisplayHeight")
    }

    fun startRecordScreen() {
        try {
            try {
                mFileName = pluginBinding!!.applicationContext.externalCacheDir?.absolutePath
                mFileName += "/$videoName.mp4"
            } catch (e: IOException) {
                println("Error creating name")
                return
            }
            mMediaRecorder?.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            if (recordAudio!!) {
                mMediaRecorder?.setAudioSource(MediaRecorder.AudioSource.MIC);
                mMediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
                mMediaRecorder?.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            } else {
                mMediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            }
            mMediaRecorder?.setOutputFile(mFileName)
            mMediaRecorder?.setVideoSize(mDisplayWidth, mDisplayHeight)
            mMediaRecorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            mMediaRecorder?.setVideoEncodingBitRate(5 * mDisplayWidth * mDisplayHeight)
            mMediaRecorder?.setVideoFrameRate(30)

            mMediaRecorder?.prepare()
            mMediaRecorder?.start()
        } catch (e: IOException) {
            Log.d("--INIT-RECORDER", e.message + "")
            println("Error startRecordScreen")
            println(e.message)
        }
        val permissionIntent = mProjectionManager?.createScreenCaptureIntent()
        ActivityCompat.startActivityForResult(
            activityBinding!!.activity!!,
            permissionIntent!!,
            SCREEN_RECORD_REQUEST_CODE,
            null
        )
    }

    fun stopRecordScreen() {
        try {
            println("stopRecordScreen")
            mMediaRecorder?.stop()
            mMediaRecorder?.reset()
            println("stopRecordScreen success")

        } catch (e: Exception) {
            Log.d("--INIT-RECORDER", e.message + "")
            println("stopRecordScreen error")
            println(e.message)

        } finally {
            stopScreenSharing()
        }
    }

    private fun createVirtualDisplay(): VirtualDisplay? {
        try {
            return mMediaProjection?.createVirtualDisplay(
                "MainActivity", mDisplayWidth, mDisplayHeight, mScreenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, mMediaRecorder?.surface, null, null
            )
        } catch (e: Exception) {
            println("createVirtualDisplay err")
            println(e.message)
            return null
        }
    }

    private fun stopScreenSharing() {
        if (mVirtualDisplay != null) {
            mVirtualDisplay?.release()
            if (mMediaProjection != null && mMediaProjectionCallback != null) {
                mMediaProjection?.unregisterCallback(mMediaProjectionCallback!!)
                mMediaProjection?.stop()
                mMediaProjection = null
            }
            Log.d("TAG", "MediaProjection Stopped")
        }
    }

    inner class MediaProjectionCallback : MediaProjection.Callback() {
        override fun onStop() {
            mMediaRecorder?.reset()
            mMediaProjection = null
            stopScreenSharing()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = binding;
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding;
        val channel = MethodChannel(pluginBinding!!.binaryMessenger, "flutter_screen_recording")
        channel.setMethodCallHandler(this)
        activityBinding!!.addActivityResultListener(this);
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding;
    }

    override fun onDetachedFromActivity() {}
}