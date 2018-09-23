//
//  AVController.swift
//
//  Created by Peter de Tagyos on 8/3/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import AVFoundation
import UIKit


class AVController : NSObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    public enum CameraPosition {
        case front
        case rear
    }

    public enum CaptureType {
        case photo
        case video
    }

    public enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case photoOutputFailed
        case videoOutputFailed
        case outputTypeNotReady
        case unknown
    }

    // Public Properties
    
    var currentCameraPosition: CameraPosition?
    var flashMode = AVCaptureDevice.FlashMode.off
    var captureType: CaptureType {
        get {
            return self.currentCaptureType
        }
    }
    var isRecording: Bool {
        get {
            return self.isCurrentlyRecording
        }
    }
    
    // Private Properties
    
    private var captureSession: AVCaptureSession? = nil
    private var frontCamera: AVCaptureDevice? = nil
    private var rearCamera: AVCaptureDevice? = nil
    private var microphone: AVCaptureDevice? = nil

    private var frontCameraInput: AVCaptureDeviceInput?
    private var rearCameraInput: AVCaptureDeviceInput?
    private var microphoneInput: AVCaptureDeviceInput?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var currentCaptureType: CaptureType = .photo
    private var isCurrentlyRecording: Bool = false
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    private var videoCaptureCompletionBlock: ((URL?, Error?) -> Void)?

    
    // MARK: - Public Interface
    
    func initialize(onCompletion completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue(label: "initialize").async {
            do {
                self.createCaptureSession()
                try self.configureCaptureDevices()
                try self.configureInputs()
                self.captureSession?.startRunning()
            }
                
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func capturePhoto(onCompletion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else { onCompletion(nil, CameraControllerError.captureSessionIsMissing); return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = onCompletion
    }
    
    func startRecordingVideo(to fileUrl: URL) throws {
        if self.currentCaptureType != .video || self.videoOutput == nil {
            throw CameraControllerError.outputTypeNotReady
        }
        self.videoOutput!.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    func stopRecordingVideo(onCompletion: @escaping (URL?, Error?) -> Void) {
        if self.currentCaptureType != .video || self.videoOutput == nil {
            onCompletion(nil, CameraControllerError.outputTypeNotReady)
            return
        }

        self.videoCaptureCompletionBlock = onCompletion
        self.videoOutput?.stopRecording()
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        // Remove any previously embedded preview views
        view.removeAllSubviews()
        
        if self.previewLayer == nil {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)            
        }
        
        // Preview using the current orientation
        var desiredOrientation: AVCaptureVideoOrientation = .portrait
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            // Video orientation is opposite device orientation. Go figure.
            desiredOrientation = .landscapeRight
        case .landscapeRight:
            // Video orientation is opposite device orientation. Go figure.
            desiredOrientation = .landscapeLeft
        default:
            desiredOrientation = .portrait
        }
        self.previewLayer?.connection?.videoOrientation = desiredOrientation
        
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
    
    func setCaptureType(to capture: CaptureType) throws {
        if capture == .photo {
            try configurePhotoOutput()
        } else {
            try configureVideoOutput()
        }
    }
    
    func useCamera(position: CameraPosition) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }

        if (position == .front && self.currentCameraPosition != .front) ||
            (position == .rear && self.currentCameraPosition != .rear) {
            // Switch the current camera
            captureSession.beginConfiguration()
            if position == .front {
                try switchToFrontCamera()
            } else {
                try switchToRearCamera()
            }
            captureSession.commitConfiguration()
        }
    }
    
    
    // MARK: - AVCapturePhotoCaptureDelegate Methods
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let err = error {
            self.photoCaptureCompletionBlock?(nil, err)
            return
        }

        let img = UIImage(data: photo.fileDataRepresentation()!)
        
        self.photoCaptureCompletionBlock?(img, nil)
    }
    
    
    // MARK: - AVCaptureFileOutputRecordingDelegate Methods
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
        self.isCurrentlyRecording = true
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if error != nil {
            self.videoCaptureCompletionBlock?(nil, error)
            return
        }

        self.isCurrentlyRecording = false
        self.videoCaptureCompletionBlock?(outputFileURL, nil)
    }


    // MARK: - Private Methods
    
    private func createCaptureSession() {
        self.captureSession = AVCaptureSession()
    }
    
    private func configureCaptureDevices() throws {
        // Get front and rear cameras if possible
        let videoSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        
        let cameras = (videoSession.devices.compactMap { $0 })
        if cameras.isEmpty {
            throw CameraControllerError.noCamerasAvailable
        }
        
        for camera in cameras {
            if camera.position == .front {
                self.frontCamera = camera
            }
            
            if camera.position == .back {
                self.rearCamera = camera
                
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
        }
        
        // Get microphone if possible
        let audioSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: AVMediaType.audio, position: .unspecified)
        let mics = (audioSession.devices.compactMap{ $0 })
        if !mics.isEmpty {
            self.microphone = mics[0]
        }

    }
    
    private func configureInputs() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        // Prefer the rear camera, if available
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
            }
            self.currentCameraPosition = .rear
        
        } else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
            } else {
                throw CameraControllerError.inputsAreInvalid
            }
            
            self.currentCameraPosition = .front

        } else {
            throw CameraControllerError.noCamerasAvailable
        }
        
        // Add audio input
        if let mic = self.microphone {
            self.microphoneInput = try AVCaptureDeviceInput(device: mic)
            if self.microphoneInput != nil {
                if captureSession.canAddInput(self.microphoneInput!) {
                    captureSession.addInput(self.microphoneInput!)
                }
            }
        }
    }
    
    private func configurePhotoOutput() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }

        if self.captureType == .photo && self.photoOutput != nil { return }
        
        if self.captureType == .video && self.videoOutput != nil {
            self.captureSession?.removeOutput(self.videoOutput!)
        }
        
        self.photoOutput = AVCapturePhotoOutput()
        if self.photoOutput != nil {
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            
            if captureSession.canAddOutput(self.photoOutput!) {
                captureSession.addOutput(self.photoOutput!)
            }
            
            self.currentCaptureType = .photo
            
        } else {
            throw CameraControllerError.photoOutputFailed
        }
    }
    
    private func configureVideoOutput() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        if self.captureType == .video && self.videoOutput != nil { return }
        
        if self.captureType == .photo && self.photoOutput != nil {
            self.captureSession?.removeOutput(self.photoOutput!)
        }

        self.videoOutput = AVCaptureMovieFileOutput()
        if self.videoOutput != nil {
            if captureSession.canAddOutput(self.videoOutput!) {
                captureSession.addOutput(self.videoOutput!)
            }
            
            self.currentCaptureType = .video

        } else {
            throw CameraControllerError.videoOutputFailed
        }
    }
    
    private func switchToFrontCamera() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput),
            let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
        
        self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        
        captureSession.removeInput(rearCameraInput)
        
        if captureSession.canAddInput(self.frontCameraInput!) {
            captureSession.addInput(self.frontCameraInput!)
            
            // Make sure our current flash mode is supported
            if !self.photoOutput!.supportedFlashModes.contains(self.frontCamera!.flashMode) {
                self.frontCamera!.flashMode = .off
            }
            
            self.currentCameraPosition = .front
        
        } else {
            throw CameraControllerError.invalidOperation
        }
    }
    
    private func switchToRearCamera() throws {
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput),
            let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
        
        self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        
        captureSession.removeInput(frontCameraInput)
        
        if captureSession.canAddInput(self.rearCameraInput!) {
            captureSession.addInput(self.rearCameraInput!)
            
            self.currentCameraPosition = .rear
            
        } else {
            throw CameraControllerError.invalidOperation
        }
    }
    
}
