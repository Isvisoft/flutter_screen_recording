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
import android.os.Environment
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat.getSystemService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.io.IOException

import com.foregroundservice.ForegroundService


class FlutterScreenRecordingPlugin(
        private val registrar: Registrar
) : MethodCallHandler, PluginRegistry.ActivityResultListener{

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
                mMediaProjection = mProjectionManager?.getMediaProjection(resultCode, data!!)
                mMediaProjection?.registerCallback(mMediaProjectionCallback, null)
                mVirtualDisplay = createVirtualDisplay()
                _result.success(true)
                return true
            } else {
                ForegroundService.stopService(registrar.context())
                _result.success(false)
            }
        }
        return false
    }

    override fun  onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "startRecordScreen") {
            try {

                _result = result
                ForegroundService.startService(registrar.context(), "Your screen is being recorded")
                mProjectionManager = registrar.context().applicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?

                val metrics = DisplayMetrics()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    mMediaRecorder = MediaRecorder(registrar.context().applicationContext)
                } else {
                    @Suppress("DEPRECATION")
                    mMediaRecorder = MediaRecorder()
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    val display = registrar.activity()!!.display
                    display?.getRealMetrics(metrics)
                } else {
                    val defaultDisplay = registrar.context().applicationContext.getDisplay()
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
        } else if (call.method == "stopRecordScreen") {
            try {
                ForegroundService.stopService(registrar.context())
                if (mMediaRecorder != null) {
                    stopRecordScreen()
                    result.success(mFileName)
                } else {
                    result.success("")
                }
            } catch (e: Exception) {
                result.success("")
            }
        } else {
            result.notImplemented()
        }
    }

    private fun calculeResolution(metrics: DisplayMetrics) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            mDisplayHeight = metrics.heightPixels
            mDisplayWidth = metrics.widthPixels
        }else{
            var maxRes = 1280.0;
            if (metrics.scaledDensity >= 3.0f) {
                maxRes = 1920.0;
            }
            if (metrics.widthPixels > metrics.heightPixels) {
                val rate = metrics.widthPixels / maxRes
                mDisplayWidth = maxRes.toInt()
                mDisplayHeight = (metrics.heightPixels / rate).toInt()
            } else {
                val rate = metrics.heightPixels / maxRes
                mDisplayHeight = maxRes.toInt()
                mDisplayWidth = (metrics.widthPixels / rate).toInt()
            }
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
                mFileName = registrar.context().getExternalCacheDir()?.getAbsolutePath()
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
            Log.d("--INIT-RECORDER", e.message+"")
            println("Error startRecordScreen")
            println(e.message)
        }
        val permissionIntent = mProjectionManager?.createScreenCaptureIntent()
        ActivityCompat.startActivityForResult(registrar.activity()!!, permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)
    }

    fun stopRecordScreen() {
        try {
            println("stopRecordScreen")
            mMediaRecorder?.stop()
            mMediaRecorder?.reset()
            println("stopRecordScreen success")

        } catch (e: Exception) {
            Log.d("--INIT-RECORDER", e.message +"")
            println("stopRecordScreen error")
            println(e.message)

        } finally {
            stopScreenSharing()
        }
    }

    private fun createVirtualDisplay(): VirtualDisplay? {
        return mMediaProjection?.createVirtualDisplay("MainActivity", mDisplayWidth, mDisplayHeight, mScreenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, mMediaRecorder?.surface, null, null)
    }

    private fun stopScreenSharing() {
        if (mVirtualDisplay != null) {
            mVirtualDisplay?.release()
            if (mMediaProjection != null) {
                mMediaProjection?.unregisterCallback(mMediaProjectionCallback)
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
}