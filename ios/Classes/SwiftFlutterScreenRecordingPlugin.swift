import Flutter
import UIKit
import ReplayKit

public class SwiftFlutterScreenRecordingPlugin: NSObject, FlutterPlugin {
    
 let recorder = RPScreenRecorder.shared()
 var videoOutputURL : URL
    var  videoWriter : AVAssetWriter?

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
        startRecording()

    }else if(call.method == "stopRecordScreen"){
    stopRecording()

    }
  }


    @objc func startRecording2() {
        //Use ReplayKit to record the screen

        //Create the file path to write to
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("MyVideo.mp4"))

        //Check the file does not already exist by deleting it if it does
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}


        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mp4)
        } catch let writerError as NSError {
            print("Error opening video file", writerError);
            videoWriter = nil;
            return;
        }

        //Create the video settings
        if #available(iOS 11.0, *) {
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : AVVideoCodecType.h264,
                AVVideoWidthKey  : 1920,  //Replace as you need
                AVVideoHeightKey : 1080   //Replace as you need
            ]
        } else {
            // Fallback on earlier versions
        }

        //Create the asset writer input object whihc is actually used to write out the video
        //with the video settings we have created
        AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings);
        videoWriter.add(AVAssetWriterInput);

        //Tell the screen recorder to start capturing and to call the handler when it has a
        //sample 
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().startCapture(handler: { (cmSampleBuffer, rpSampleType, error) in
                
                guard error == nil else {
                    //Handle error
                    print("Error starting capture");
                    return;
                }
                
                switch rpSampleType {
                case RPSampleBufferType.video:
                    print("writing sample....");
                    if self.videoWriter.status == AVAssetWriter.Status.unknown {
                        
                        if (( self.videoWriter.startWriting ) != nil) {
                            print("Starting writing");
                            self.videoWriter.startWriting()
                            self.videoWriter.startSession(atSourceTime:  CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                        }
                    }
                    
                    if self.videoWriter.status == AVAssetWriter.Status.writing {
                        if (self.videoWriterInput.isReadyForMoreMediaData == true) {
                            print("Writting a sample");
                            if  self.videoWriterInput.append(cmSampleBuffer) == false {
                                print(" we have a problem writing video")
                            }
                        }
                    }
                    
                default:
                    print("not a video sample, so ignore");
                }
            } )
        } else {
            // Fallback on earlier versions
        }
    }

    @objc func stoprecording2() {
        //Stop Recording the screen
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture( handler: { (error) in
                print("stopping recording");
            })
        } else {
            // Fallback on earlier versions
        }

        self.videoWriterInput.markAsFinished();
        self.videoWriter.finishWriting {
            print("finished writing video");

            //Now save the video
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL)
            }) { saved, error in
                if saved {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                if error != nil {
                    print("Video did not save for some reason", error.debugDescription);
                    debugPrint(error?.localizedDescription ?? "error is nil");
                }
            }
        }
    
}
    
    
    
    func startRecording() {
        
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        
        
        recorder.isMicrophoneEnabled = false
        
        
        if #available(iOS 10.0, *) {
            recorder.startRecording{ [unowned self] (error) in
                
                guard error == nil else {
                    print("There was an error starting the recording.")
                    print(error.debugDescription)
                    print(".------------------")
                    print(error?.localizedDescription)
                    
                    return
                }
                
                print("Started Recording Successfully")
                
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    
    func stopRecording() {
        
        recorder.stopRecording { [unowned self] (preview, error) in
            print("Stopped recording")
            
            guard preview != nil else {
                print("Preview controller is not available.")
                print(error.debugDescription)
                print(".------------------")
                print(error?.localizedDescription)
                return
            }
            
            print("Stopped Recording Successfully")
            
            
            // let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            
            // let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
            //     self.recorder.discardRecording(handler: { () -> Void in
            //         print("Recording suffessfully deleted.")
            //     })
            // })
            
            // let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
            //     preview?.previewControllerDelegate = self
            //     self.present(preview!, animated: true, completion: nil)
            // })
            
            // alert.addAction(editAction)
            // alert.addAction(deleteAction)
            // self.present(alert, animated: true, completion: nil)
            
            // self.isRecording = false
            // self.viewReset()
            
        }
        
    }
}
