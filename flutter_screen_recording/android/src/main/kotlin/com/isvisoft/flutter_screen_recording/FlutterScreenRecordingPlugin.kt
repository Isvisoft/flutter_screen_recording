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
import android.graphics.Point

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
<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
    var mDisplayHeight: Int = 720
    var storePath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).absolutePath + File.separator
=======
    var mDisplayHeight: Int = 800
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
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
                //initMediaRecorder();

                mMediaProjectionCallback = MediaProjectionCallback()
                mMediaProjection = mProjectionManager?.getMediaProjection(resultCode, data!!)
                mMediaProjection?.registerCallback(mMediaProjectionCallback, null)
                mVirtualDisplay = createVirtualDisplay()
                _result.success(true)
                return true
            } else {
                _result.success(false)
            }
        }
        return false
    }

    override fun  onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "startRecordScreen") {
            try {
                _result = result
<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
                mMediaRecorder = MediaRecorder()

                mProjectionManager = registrar.context().applicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?
=======
                ForegroundService.startService(registrar.context(), "Your screen is being recorded")
                mProjectionManager = registrar.context().applicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?

                val metrics = DisplayMetrics()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    mMediaRecorder = MediaRecorder(registrar.context().applicationContext)
                } else {
                    @Suppress("DEPRECATION")
                    mMediaRecorder = MediaRecorder()
                }
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt

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
<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
                initMediaRecorder();
=======
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
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

<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
    fun calculeResolution(screenSize: Point) {

        val screenRatio: Double = (screenSize.x.toDouble() / screenSize.y.toDouble())

        println(screenSize.x.toString() + " --- " + screenSize.y.toString())
        var height: Double = mDisplayWidth / screenRatio;
        println("height - " + height)

        mDisplayHeight = height.toInt()

/*        mDisplayWidth = 2560;
        mDisplayHeight = 1440;*/

=======
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
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
        println("Scaled Density")
        //println(metrics.scaledDensity)
        println("Original Resolution ")
        //println(metrics.widthPixels.toString() + " x " + metrics.heightPixels)
        println("Calcule Resolution ")
        println("$mDisplayWidth x $mDisplayHeight")
    }

    fun initMediaRecorder() {
        mMediaRecorder?.setVideoSource(MediaRecorder.VideoSource.SURFACE)

        //mMediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        mMediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);

        if (recordAudio!!) {
            mMediaRecorder?.setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION);
            mMediaRecorder?.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);//AAC //HE_AAC
            mMediaRecorder?.setAudioEncodingBitRate(16 * 44100);
            mMediaRecorder?.setAudioSamplingRate(44100);
        }

        mMediaRecorder?.setVideoEncoder(MediaRecorder.VideoEncoder.H264)

        println(mDisplayWidth.toString() + " " + mDisplayHeight);
        mMediaRecorder?.setVideoSize(mDisplayWidth, mDisplayHeight)
        mMediaRecorder?.setVideoFrameRate(30)

        mMediaRecorder?.setOutputFile("${storePath}${videoName}.mp4")

        println("file --- " + "${storePath}${videoName}.mp4")

        mMediaRecorder?.setVideoEncodingBitRate(5 * mDisplayWidth * mDisplayHeight)
        mMediaRecorder?.prepare()
    }

    fun startRecordScreen() {
        try {
<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
            //mMediaRecorder?.prepare()

=======
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
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
            mMediaRecorder?.start()

        } catch (e: IOException) {
<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
            println("ERR");
            Log.d("--INIT-RECORDER", e.message)
=======
            println("hola")
            Log.d("--INIT-RECORDER", e.message+"")
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
            println("Error startRecordScreen")
            println(e.message)
        }
        val permissionIntent = mProjectionManager?.createScreenCaptureIntent()
<<<<<<< HEAD:android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
        ActivityCompat.startActivityForResult(registrar.activity(), permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)

=======
        ActivityCompat.startActivityForResult(registrar.activity()!!, permissionIntent!!, SCREEN_RECORD_REQUEST_CODE, null)
>>>>>>> d82fbe461fe27fac2092c5231ee04bdd2983b908:flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
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
        val windowManager = registrar.context().applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics: DisplayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        val screenSize = Point()
        windowManager.defaultDisplay.getRealSize(screenSize);
        calculeResolution(screenSize)
        mScreenDensity = metrics.densityDpi
        println("density " + mScreenDensity.toString())
        println("msurface " + mMediaRecorder?.getSurface())
        println("aaa" + mDisplayWidth.toString() + " " + mDisplayHeight);

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