//
//  IRCClient.swift
//
//  Created by Peter de Tagyos on 8/21/17.
//  Copyright © 2017 Peter de Tagyos. All rights reserved.
//

import Foundation


protocol IRCClientDelegate: class {
    func ircHandshakeCompleted()
    func ircJoinedChannel()
    func ircMessageReceived(_ message: IRCMessage)
    func ircSessionClosed()
}

class IRCClient: NSObject, SocketDelegate {
    private let LINE_ENDING = "\r\n"
    
    weak var delegate: IRCClientDelegate? = nil
    
    var host: String {
        get {
            return self.socket.host
        }
    }
    var port: Int {
        get {
            return self.socket.port
        }
    }

    private var socket: Socket!
    private var nickName: String = ""
    private var user: String = ""
    private var realName: String = ""
    private var authToken: String = ""
    
    private var isRegistered = false
    private var isWaitingForRegistration = false
    private var isReady = false

    
    // MARK: - Initialization -
    
    init(socket: Socket) {
        super.init()
        
        self.socket = socket
        socket.delegate = self
    }

    
    // MARK: - Public Interface -
    
    func close() {
        self.socket.close()
    }
    
    func register(nickName: String, user: String, realName: String, authToken: String) {
        self.nickName = nickName
        self.user = user
        self.realName = realName
        self.authToken = authToken
        
        self.socket.open()
    }

    func join(channel: String) {
        if channel.hasPrefix("#") {
            sendCommand("JOIN \(channel)")
        }
    }
    
    func sendCommand(_ cmd: String) {
        L.debug("Sending Message: \(cmd)")
        let msg = cmd + self.LINE_ENDING
        self.socket.sendMessage(message: msg)
    }

    func sendMessage(_ msg: String, toChannel channel: String) {
        if channel.hasPrefix("#") {
            sendCommand("PRIVMSG \(channel) :\(msg)")
        }
    }

    func sendMessage(_ msg: String, toNickname nick: String) {
        if nick.hasPrefix("#") {
            sendCommand("PRIVMSG \(nick) :\(msg)")
        }
    }

    
    // MARK: - SocketDelegate Methods -
    
    func socketDidClose() {
        L.debug("Socket closed")
        self.isRegistered = false
    }

    func socketDidOpen() {
        L.debug("Socket opened")
    }
    
    func socketDidReceiveMessage(msg: String) {
        L.debug("Socket received message: \(msg)")

        let msgList = msg.components(separatedBy: self.LINE_ENDING)
        for m in msgList {
            if m.hasPrefix("PING") {
                pong(m)
            } else {
                handleMessage(m)
            }
        }
    }

    func socketIsReady() {
        L.debug("Socket is ready")

        if !self.isRegistered && !self.isWaitingForRegistration {
            self.isWaitingForRegistration = true
            sendCommand("PASS oauth:\(self.authToken)")
            sendCommand("NICK \(self.nickName)")
        }
    }
    
    
    // MARK: - Private Methods -
    
    private func handleMessage(_ message: String) {
        /* 
            IRC message format: optional prefix, command, command parameters
            :Name COMMAND parameter list
            Each IRC message may consist of up to three main parts: the prefix
            (OPTIONAL), the command, and the command parameters (maximum of
            fifteen (15)).  The prefix, command, and all parameters are separated
            by one ASCII space character (0x20) each.
        */
        
        var prefix: String? = nil
        var command = ""
        var params = ""
        var customPayload: String? = nil
        
        var msg = message
        
        // Check for optional custom payload
        if msg.hasPrefix("@") {
            if let idx = msg.characters.index(of: " ") {
                customPayload = msg.substring(to: idx)
                msg = msg.substring(from: msg.index(after: idx))
            }
        }
        
        // Check for optional IRC prefix
        if msg.hasPrefix(":") {
            if let idx = msg.characters.index(of: " ") {
                prefix = msg.substring(to: idx)
                msg = msg.substring(from: msg.index(after: idx))
            }
        }
        
        // Get command
        if let idx = msg.characters.index(of: " ") {
            command = msg.substring(to: idx)
            msg = msg.substring(from: msg.index(after: idx))
        }

        // Get parameter(s)
        params = msg

        switch command {
        case "001":
            self.isReady = true
            self.delegate?.ircHandshakeCompleted()
            
        default:
            let ircMsg = IRCMessage(prefix: prefix, command: command, parameters: params, customPayload: customPayload)
            self.delegate?.ircMessageReceived(ircMsg)
        }
    }
    
    private func pong(_ pingMsg: String) {
        let echoMsg = pingMsg.replacingOccurrences(of: "PING :", with: "").replacingOccurrences(of: self.LINE_ENDING, with: "")
        self.isRegistered = true
        self.isWaitingForRegistration = false
        
        sendCommand("PONG :\(echoMsg)")
    }
    
}
