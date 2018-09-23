//
//  Permissions.swift
//
//  Created by Peter de Tagyos on 7/26/17.
//  Copyright © 2017 Peter de Tagyos. All rights reserved.
//

import AVFoundation
import Foundation
import Photos


public enum PermissionStatus: Int, CustomStringConvertible {
    case
        authorized,
        unauthorized,
        unknown,
        disabled
    
    public var description: String {
        switch self {
        case .authorized:
            return "Authorized"
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown"
        case .disabled:
            return "Disabled"
        }
    }
}


public class Permissions {
    
    public static func cameraStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .authorized:
            return .authorized
        case .restricted, .denied:
            return .unauthorized
        case .notDetermined:
            return .unknown
        }
    }

    public static func requestCamera(onCompletion: @escaping (_ result: PermissionStatus)->Void) {
        let status = cameraStatus()
        if status == .unknown {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if granted {
                    onCompletion(.authorized)
                } else {
                    onCompletion(.unauthorized)
                }
            })
        } else {
            onCompletion(status)
        }
    }
    
    public static func microphoneStatus() -> PermissionStatus {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case AVAudioSession.RecordPermission.granted:
            return .authorized
        case AVAudioSession.RecordPermission.denied:
            return .unauthorized
        default:
            return .unknown
        }
    }
    
    public static func requestMicrophone(onCompletion: @escaping (_ result: PermissionStatus)->Void) {
        let status = microphoneStatus()
        if status == .unknown {
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    onCompletion(.authorized)
                } else {
                    onCompletion(.unauthorized)
                }
            })
        } else {
            onCompletion(status)
        }
    }
    
    public static func photoStatus() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .unauthorized
        case .notDetermined:
            return .unknown
        }
    }
    
    public static func requestPhoto(onCompletion: @escaping (_ result: PermissionStatus)->Void) {
        let status = cameraStatus()
        if status == .unknown {
            PHPhotoLibrary.requestAuthorization({ (status) in
                switch status {
                case .authorized:
                    onCompletion(.authorized)
                case .denied, .restricted:
                    onCompletion(.unauthorized)
                case .notDetermined:
                    onCompletion(.unknown)
                }
            })
            
        } else {
            onCompletion(status)
        }
    }
    
}
