import Flutter
import UIKit
import ReplayKit
import Photos

public class SwiftFlutterScreenRecordingPlugin: NSObject, FlutterPlugin {
    
let recorder = RPScreenRecorder.shared()

var videoOutputURL : URL?
var videoWriter : AVAssetWriter?

var audioInput:AVAssetWriterInput!
var videoWriterInput : AVAssetWriterInput?
var nameVideo: String = ""
var recordAudio: Bool = false;
var myResult: FlutterResult?
let screenSize = UIScreen.main.bounds
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_screen_recording", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterScreenRecordingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    if(call.method == "startRecordScreen"){
         myResult = result
         let args = call.arguments as? Dictionary<String, Any>

         self.recordAudio = (args?["audio"] as? Bool)!
         self.nameVideo = (args?["name"] as? String)!+".mp4"
         startRecording()

    }else if(call.method == "stopRecordScreen"){
        if(videoWriter != nil){
            stopRecording()
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            result(String(documentsPath.appendingPathComponent(nameVideo)))
        }
         result("")
    }
  }


    @objc func startRecording() {

        //Use ReplayKit to record the screen
        //Create the file path to write to
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(nameVideo))

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
            
            var codec = AVVideoCodecJPEG;
            
            if(recordAudio){
                codec = AVVideoCodecH264;
            }
            
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : codec,
                AVVideoWidthKey  : screenSize.width,
                AVVideoHeightKey : screenSize.height
            ]
                        
            if(recordAudio){
                
                let audioOutputSettings: [String : Any] = [
                    AVNumberOfChannelsKey : 2,
                    AVFormatIDKey : kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                ]
                
                audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
                videoWriter?.add(audioInput)
            
            }


        //Create the asset writer input object whihc is actually used to write out the video
         videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings);
         videoWriter?.add(videoWriterInput!);
            
        }

        //Tell the screen recorder to start capturing and to call the handler
        if #available(iOS 11.0, *) {
            
            if(recordAudio){
                RPScreenRecorder.shared().isMicrophoneEnabled=true;
            }else{
                RPScreenRecorder.shared().isMicrophoneEnabled=false;

            }
            
            RPScreenRecorder.shared().startCapture(
            handler: { (cmSampleBuffer, rpSampleType, error) in
                guard error == nil else {
                    //Handle error
                    print("Error starting capture");
                    self.myResult!(false)
                    return;
                }

                switch rpSampleType {
                case RPSampleBufferType.video:
                    print("writing sample....");
                    if self.videoWriter?.status == AVAssetWriter.Status.unknown {

                        if (( self.videoWriter?.startWriting ) != nil) {
                            print("Starting writing");
                            self.myResult!(true)
                            self.videoWriter?.startWriting()
                            self.videoWriter?.startSession(atSourceTime:  CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                        }
                    }

                    if self.videoWriter?.status == AVAssetWriter.Status.writing {
                        if (self.videoWriterInput?.isReadyForMoreMediaData == true) {
                            print("Writting a sample");
                            if  self.videoWriterInput?.append(cmSampleBuffer) == false {
                                print(" we have a problem writing video")
                                self.myResult!(false)
                            }
                        }
                    }


                default:
                   print("not a video sample, so ignore");
                }
            } ){(error) in
                        guard error == nil else {
                           //Handle error
                           print("Screen record not allowed");
                           self.myResult!(false)
                           return;
                       }
                   }
        } else {
            //Fallback on earlier versions
        }
    }

    @objc func stopRecording() {
        //Stop Recording the screen
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture( handler: { (error) in
                print("stopping recording");
            })
        } else {
          //  Fallback on earlier versions
        }

        self.videoWriterInput?.markAsFinished();
        self.audioInput?.markAsFinished();
        
        self.videoWriter?.finishWriting {
            print("finished writing video");

            //Now save the video
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL!)
            }) { saved, error in
                if saved {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    //self.present(alertController, animated: true, completion: nil)
                }
                if error != nil {
                    print("Video did not save for some reason", error.debugDescription);
                    debugPrint(error?.localizedDescription ?? "error is nil");
                }
            }
        }
    
}
    
}
