//
// Created by Kyosuke Kawamura on 2022/02/07.
//

import UIKit
import AVFoundation

public class APVideoRecorder: UIViewController {
    
    private var cameraView: UIView?
    
    private var recordButton: RecordButton?
    
    private let captureSession = AVCaptureSession()
    
    private let movieOutput = AVCaptureMovieFileOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var activeInput: AVCaptureDeviceInput!
    
    private var outputURL: URL!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // create & add view for camera
        cameraView = UIView(frame: view.frame)
        view.addSubview(cameraView!)
        
        // set record button
        recordButton = RecordButton()
        recordButton?.delegate = self
        
        if !setupSession() {
            return
        }
        
        // Configure previewLayer
        setupPreview()
        startSession()
        
        // add button after start session
        recordButton?.translatesAutoresizingMaskIntoConstraints = false
        cameraView?.addSubview(recordButton!)
        NSLayoutConstraint.activate([
            recordButton!.heightAnchor.constraint(equalToConstant: recordButton!.frame.height),
            recordButton!.widthAnchor.constraint(equalToConstant: recordButton!.frame.height),
            recordButton!.centerXAnchor.constraint(equalTo: cameraView!.centerXAnchor, constant: 0),
            recordButton!.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -recordButton!.frame.height)
        ])
    }
    
    private func setupSession() -> Bool {
        // set video quaility
        captureSession.sessionPreset = .high
        
        // Setup Camera & Microphone
        if (!setCaptureDevice(type: .video) || !setCaptureDevice(type: .audio)) {
            return false
        }
        
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        return true
    }
    
    private func setCaptureDevice(type: AVMediaType) -> Bool {
        let device = AVCaptureDevice.default(for: type)!
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                if (type == .video) {
                    activeInput = input
                }
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        return true
    }
    
    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView!.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView?.layer.addSublayer(previewLayer)
    }
    
    private func startSession() {
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    private func createTempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    private func startRecording() {
        if movieOutput.isRecording == false {
            let connection = movieOutput.connection(with: AVMediaType.video)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            if (device.isSmoothAutoFocusSupported) {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
            }
            
            outputURL = createTempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        } else {
            stopRecording()
        }
    }
    
    private func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    @objc private func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title: String = (error == nil) ? "Success" : "Error"
        let message: String = (error == nil) ? "Video was saved." : "Video failed to save."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: false)
    }
}

extension APVideoRecorder: RecordButtonDelegate {
    func start(_ sender: RecordButton) {
        print("start")
        startRecording()
    }
    
    func end(_ sender: RecordButton) {
        print("end")
        stopRecording()
    }
}

extension APVideoRecorder: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("delegate fileOutput")
        
        if let e = error {
            print("Error recording movie: \(e.localizedDescription)")
            return
        }
        
        let videoRecorded = outputURL! as URL
        print("outputURL \(videoRecorded)")
        UISaveVideoAtPathToSavedPhotosAlbum(videoRecorded.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }
}
