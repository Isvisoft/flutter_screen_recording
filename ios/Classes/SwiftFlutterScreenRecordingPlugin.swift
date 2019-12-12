import Flutter
import UIKit
import ReplayKit
import Photos

public class SwiftFlutterScreenRecordingPlugin: NSObject, FlutterPlugin {

let recorder = RPScreenRecorder.shared()

var videoOutputURL : URL?
var videoWriter : AVAssetWriter?
var videoWriterInput : AVAssetWriterInput?

let screenSize = UIScreen.main.bounds

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_screen_recording", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterScreenRecordingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    print(call.method)

    if(call.method == "getPlatformVersion"){
        result("iOS " + UIDevice.current.systemVersion)

    }else if(call.method == "startRecordScreen"){
        startRecording(result: result)

    }else if(call.method == "stopRecordScreen"){
        stopRecording(result: result)

    }
  }


    @objc func startRecording(result: @escaping FlutterResult) {
        //Use ReplayKit to record the screen

        let videoName = String(Date().timeIntervalSince1970) + ".mp4"

        //Create the file path to write to
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(videoName))

        //Check the file does not already exist by deleting it if it does
        do {
            try FileManager.default.removeItem(at: videoOutputURL!)
        } catch {}


        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL!, fileType: AVFileType.mp4)
        } catch let writerError as NSError {
            print("Error opening video file", writerError);
            videoWriter = nil;
            return;
        }

        //Create the video settings
        if #available(iOS 11.0, *) {
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : AVVideoCodecType.h264,
                //AVVideoCodecKey: AVVideoCodecJPEG,
                //AVVideoCompressionPropertiesKey: [AVVideoQualityKey: 1],
                AVVideoWidthKey  : screenSize.width,
                AVVideoHeightKey : screenSize.height
            ]



        //Create the asset writer input object whihc is actually used to write out the video
        //with the video settings we have created
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings);
            videoWriter?.add(videoWriterInput!);

        }
        result(nil)


        //Tell the screen recorder to start capturing and to call the handler when it has a
        //sample
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().startCapture(handler: { (cmSampleBuffer, rpSampleType, error) in

                guard error == nil else {
                    //Handle error
                    print("Error starting capture");
                    //result(FlutterError(code: error!.localizedDescription, message: error?.localizedDescription, details: nil))
                    return;
                }

                print("rpSampleType")
                print(rpSampleType)

                switch rpSampleType {
                case RPSampleBufferType.video:
                    print("writing sample....");
                    if self.videoWriter?.status == AVAssetWriter.Status.unknown {

                        if (( self.videoWriter?.startWriting ) != nil) {
                            print("Starting writing");
                            self.videoWriter?.startWriting()
                            self.videoWriter?.startSession(atSourceTime:  CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                        }
                    }

                    if self.videoWriter?.status == AVAssetWriter.Status.writing {
                        if (self.videoWriterInput?.isReadyForMoreMediaData == true) {
                            print("Writting a sample");
                            if  self.videoWriterInput?.append(cmSampleBuffer) == false {
                                print(" we have a problem writing video")
                            }
                        }
                    }

                default:
                    print("not a video sample, so ignore");
                }
            } )
        } else {
            //Fallback on earlier versions
        }
    }

    @objc func stopRecording(result: @escaping FlutterResult) {
        //Stop Recording the screen
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture( handler: { (error) in
                print("stopping recording");
            })
        } else {
          //  Fallback on earlier versions
        }

        self.videoWriterInput?.markAsFinished();
        self.videoWriter?.finishWriting {
            print("finished writing video");

            //Now save the video
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL!)
            }) { saved, error in
                if saved {
                    result(self.videoOutputURL!.path)
                    //self.present(alertController, animated: true, completion: nil)
                }
                if error != nil {
                    result(FlutterError(code: error!.localizedDescription, message: error?.localizedDescription, details: nil))
                    print("Video did not save for some reason", error.debugDescription);
                    debugPrint(error?.localizedDescription ?? "error is nil");
                }
            }
        }

}

}
