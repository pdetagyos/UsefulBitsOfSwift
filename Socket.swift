//
//  Socket.swift
//
//  Created by Peter de Tagyos on 8/21/17.
//  Copyright © 2017 Peter de Tagyos. All rights reserved.
//

import Foundation


protocol SocketDelegate: class {
    func socketDidClose()
    func socketDidOpen()
    func socketDidReceiveMessage(msg: String)
    func socketIsReady()
}


public class Socket: NSObject, StreamDelegate {
    
    var host: String = ""
    var port: Int = 0
    
    weak var delegate: SocketDelegate? = nil
    
    private var inputStream: InputStream? = nil
    private var outputStream: OutputStream? = nil
    private var isOpen: Bool = false
    

    // MARK: - Initialization -
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    
    // MARK: - Public Interface -
    
    func open() {
        if isOpen {
            L.debug("Socket is already open")
            return
        }
        
        Stream.getStreamsToHost(withName: self.host, port: self.port, inputStream: &self.inputStream, outputStream: &self.outputStream)
        
        self.inputStream!.schedule(in: .main, forMode: .default)
        self.outputStream!.schedule(in: .main, forMode: .default)

        self.inputStream!.delegate = self
        self.outputStream!.delegate = self

        self.inputStream!.open()
        self.outputStream!.open()
    }
    
    func close() {
        if self.isOpen {
            self.inputStream?.delegate = nil
            self.outputStream?.delegate = nil
            
            self.inputStream?.close()
            self.outputStream?.close()
            
            self.isOpen = false
        }
    }
    
    func sendMessage(message: String) {
        if self.isOpen {
            let data = NSData(data: message.data(using: .ascii)!)
            let buffer = data.bytes.assumingMemoryBound(to: UInt8.self)
            
            self.outputStream?.write(buffer, maxLength: data.length)
        }
    }
    
    
    // MARK: - StreamDelegate Methods -
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            openCompleted()
        case Stream.Event.hasBytesAvailable:
            hasBytesAvailable(stream: aStream)
        case Stream.Event.hasSpaceAvailable:
            hasSpaceAvailable()
        case Stream.Event.endEncountered:
            endEncountered(stream: aStream)
        case Stream.Event.errorOccurred:
            L.debug("Socket: stream error event")
        default:
            L.debug("Socket: Unknown stream event")
        }
    }
    
    
    // MARK: - Private Methods -
    
    private func endEncountered(stream: Stream) {
        stream.close()
        stream.remove(from: .main, forMode: .default)
        stream.remove(from: .main, forMode: .default)
        self.delegate?.socketDidClose()
    }
    
    private func hasBytesAvailable(stream: Stream) {
        if stream == self.inputStream {
            var buffer = [UInt8](repeating: 0, count: 1024)
            while self.inputStream!.hasBytesAvailable {
                let len = self.inputStream!.read(&buffer, maxLength: 1024)
                if len > 0 {
                    let output = NSString(bytes: buffer, length: len, encoding: String.Encoding.ascii.rawValue)
                    if output != nil {
                        self.delegate?.socketDidReceiveMessage(msg: output! as String)
                    }
                }
            }
        }
    }
    
    private func hasSpaceAvailable() {
        self.delegate?.socketIsReady()
    }
    
    private func openCompleted() {
        self.isOpen = true
        self.delegate?.socketDidOpen()
    }

}
